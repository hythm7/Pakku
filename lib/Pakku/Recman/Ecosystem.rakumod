use X::Pakku;
use Pakku::Log;
use Pakku::Fetch;
use Pakku::Util;
use Pakku::Recman::Index;

# An ecosystem published as a JSON array of METAs (fez, REA, a darkpan):
# the index is downloaded into the store, refreshed lazily when stale, and
# every lookup is local. Nothing is fetched or parsed until first use.
unit class Pakku::Recman::Ecosystem;
  also does Pakku::Recman::Index;

constant IS-WIN = Rakudo::Internals.IS-WIN();

has Str:D        @.mirrors is required;      # base URLs ending in '/', or local directories (tests, darkpans)
has Str:D        $.index   = 'index.json';   # relative to each mirror: fez index.json, REA META.json
has Str:D        $.source  = 'path';         # 'path' => mirror ~ meta<path>, 'source-url' => meta<source-url>
has              $.refresh = 1;              # hours between refreshes; True = always, False = never (offline)
has IO::Path:D   $.store   is required;      # ~/.pakku/.index/<name>
has Pakku::Fetch $.fetch   is required;

has %!meta;       # dist name => [ metas ]
has %!provides;   # unit      => [ metas ]
has Bool $!loaded = False;
has      $!list;  # the parsed index, between refresh and load

method index-file ( --> IO::Path:D ) { $!store.add: 'index.json' }
method !lock-file ( --> IO::Path:D ) { $!store.add: 'index.lock' }
method !mirror-file ( --> IO::Path:D ) { $!store.add: 'mirror' }

method age ( --> Duration ) { self.index-file.e ?? now - self.index-file.modified !! Duration }

method stale ( --> Bool:D ) {

  return True   unless self.index-file.e;
  return $!refresh if $!refresh ~~ Bool;

  self.age > $!refresh * 3600;

}

# fetch the index from the first mirror that works; True when a new index was stored
method refresh ( Bool:D :$force = False --> Bool:D ) {

  return False if $!refresh === False and not $force;   # norefresh: never touch the network
  return False unless $force or self.stale;

  $!store.mkdir;

  lock-file self!lock-file, {

    return False unless $force or self.stale;   # another pakku refreshed while we waited

    for @!mirrors -> $mirror {

      my $url  = $mirror.ends-with( '/' ) ?? $mirror ~ $!index !! "$mirror/$!index";
      my $part = $!store.add: "index.json.$*PID.part";

      log '🦋', header => 'IDX', msg => $!name, comment => redact $url;

      {
        CATCH { when X::Pakku::Fetch { log '🐞', header => 'IDX', msg => $!name, comment => .message; next } }
        $!fetch.download: :$url, dst => $part, :progress;
      }

      my $text = $part.slurp;
      my $list = $text.trim.starts-with( '[' ) ?? ( try Rakudo::Internals::JSON.from-json: $text ) !! Nil;

      unless $list ~~ Positional and $list.elems {
        log '🐞', header => 'IDX', msg => $!name, comment => "{ redact $url }: not an index!";
        try unlink $part;
        next;
      }

      try unlink self.index-file if IS-WIN;

      $part.rename: self.index-file;

      self!mirror-file.spurt: $mirror;

      $!list   = $list;
      $!loaded = False;

      log '🧚', header => 'IDX', msg => $!name, comment => "{ $list.elems } dists";

      return True;

    }

    die X::Pakku::Index.new: msg => $!name, comment => 'no index and refresh failed, check network or run: pakku refresh'
      unless self.index-file.e;

    log '🐞', header => 'IDX', msg => $!name, comment => "refresh failed, using index from { self.index-file.modified.DateTime.truncated-to( 'minute' ) }";

    False;

  }

}

method !load ( --> Nil ) {

  self.refresh;

  die X::Pakku::Index.new: msg => $!name, comment => 'no local index, run: pakku refresh' unless self.index-file.e;

  my $list = $!list // lock-file self!lock-file, :shared, { Rakudo::Internals::JSON.from-json: self.index-file.slurp };

  my $mirror = self!mirror-file.e ?? self!mirror-file.slurp.trim !! @!mirrors.head;

  %!meta = (); %!provides = ();

  for $list.List -> $raw {

    next unless $raw ~~ Associative and $raw<name>;

    my $source = $!source eq 'path'
      ?? ( $raw<path>.defined ?? ( $mirror.ends-with( '/' ) ?? $mirror ~ $raw<path> !! "$mirror/{ $raw<path> }" ) !! Nil )
      !! $raw<source-url>;

    without $source {
      log '🐛', header => 'IDX', msg => ~( $raw<dist> // $raw<name> ), comment => "$!name: no source, skipped!";
      next;
    }

    my %meta = self.normalise( $raw, :$source ) orelse next;

    %!meta{ %meta<name> }.push: %meta;

    %!provides{ $_ }.push: %meta for ( %meta<provides> // {} ).keys;

  }

  $!list   = Nil;
  $!loaded = True;

  log '🐛', header => 'IDX', msg => $!name, comment => "{ %!meta.elems } names, { %!provides.elems } units";

}

method by-name     ( Str:D $name ) { self!load unless $!loaded; ( %!meta{ $name }     // Empty ).List }
method by-provides ( Str:D $unit ) { self!load unless $!loaded; ( %!provides{ $unit } // Empty ).List }
method names       ( )             { self!load unless $!loaded; %!meta.keys.List }
method units       ( )             { self!load unless $!loaded; %!provides.keys.List }

# a miss on an index older than ten minutes is worth one refresh: the dist may be brand new
method refresh-on-miss ( Pakku::Spec::Raku:D :$spec! ) {

  return Nil if $!refresh === False or self.age < 600;

  return Nil unless self.refresh: :force;

  self.lookup: :$spec;

}
