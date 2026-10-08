use X::Pakku;
use Pakku::Log;
use Pakku::Fetch;
use Pakku::Util;
use Pakku::Recman::Index;

# An ecosystem published as a JSON array of METAs (fez, REA, a darkpan):
# the index is downloaded into the store, refreshed lazily when stale, and
# every lookup is local. Nothing is fetched or parsed until first use.
#
# The index is 10 to 20 MB of JSON and takes seconds to parse, so it is parsed
# once per refresh into a derived form under <store>/derived: names.json,
# provides.json (unit => dist names) and 256 by-name buckets keyed by the first
# two hex digits of the name's SHA-1. A lookup reads one small file.
unit class Pakku::Recman::Ecosystem;
  also does Pakku::Recman::Index;

constant IS-WIN = Rakudo::Internals.IS-WIN();
constant FORMAT = '2';   # bump when the derived layout changes: an old store is re-derived

has Str:D        @.mirrors is required;      # base URLs ending in '/', or local directories (tests, darkpans)
has Str:D        $.index   = 'index.json';   # relative to each mirror: fez index.json, REA META.json
has Str:D        $.source  = 'path';         # 'path' => mirror ~ meta<path>, 'source-url' => meta<source-url>
has              $.refresh = 1;              # hours between refreshes; True = always, False = never (offline)
has IO::Path:D   $.store   is required;      # ~/.pakku/.index/<name>
has Pakku::Fetch $.fetch   is required;

has %!bucket;     # hh   => { dist name => [ metas ] }, read on demand
has %!provides;   # unit => [ dist names ], read once
has $!names;      # [ dist names ], read once
has Bool $!ready = False;
has Lock $!lock .= new;

method index-file ( --> IO::Path:D ) { $!store.add: 'index.json' }
method !lock-file ( --> IO::Path:D ) { $!store.add: 'index.lock' }
method !mirror-file ( --> IO::Path:D ) { $!store.add: 'mirror' }
method !stamp-file  ( --> IO::Path:D ) { $!store.add: 'refreshed' }

method !derived     ( --> IO::Path:D ) { $!store.add: 'derived' }
method !format-file ( --> IO::Path:D ) { self!derived.add: 'format' }
method !names-file  ( --> IO::Path:D ) { self!derived.add: 'names.json' }
method !units-file  ( --> IO::Path:D ) { self!derived.add: 'provides.json' }
method !bucket-file ( Str:D $hh --> IO::Path:D ) { self!derived.add( 'by-name' ).add: "$hh.json" }

my sub bucket-of ( Str:D $name --> Str:D ) { sha1( $name ).substr( 0, 2 ).lc }

# since the last refresh, which writes its time down: file dates can not be trusted everywhere
# (Rakudo on Windows reads them as 1969). An index from before the stamp falls back to its date.
method refreshed ( --> Instant ) {

  return Instant unless self.index-file.e;

  my $stamp = self!stamp-file.e ?? ( try self!stamp-file.slurp.trim.Int ) !! Nil;

  $stamp ?? Instant.from-posix( $stamp ) !! self.index-file.modified;

}

method age ( --> Duration ) { self.refreshed.defined ?? now - self.refreshed !! Duration }

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
      self!stamp-file.spurt:  ~time;

      self!derive: $list, :$mirror;

      log '🧚', header => 'IDX', msg => $!name, comment => "{ $list.elems } dists";

      return True;

    }

    die X::Pakku::Index.new: msg => $!name, comment => 'no index and refresh failed, check network or run: pakku refresh'
      unless self.index-file.e;

    log '🐞', header => 'IDX', msg => $!name, comment => "refresh failed, using index from { self.refreshed.DateTime.truncated-to( 'minute' ) }";

    False;

  }

}

# the derived index from a parsed index list, written next to the old one and swapped in
method !derive ( $list, Str:D :$mirror --> Nil ) {

  my %bucket;
  my %provides;

  for $list.List -> $raw {

    next unless $raw ~~ Associative and $raw<name>;

    my $source = $!source eq 'path'
      ?? ( $raw<path>.defined ?? ( $mirror.ends-with( '/' ) ?? $mirror ~ $raw<path> !! "$mirror/{ $raw<path> }" ) !! Nil )
      !! $raw<source-url>;

    without $source {
      log '🐛', header => 'IDX', msg => ~( $raw<dist> // $raw<name> ), comment => "$!name: no source, skipped!";
      next;
    }

    my $normal = self.normalise( $raw, :$source );

    next without $normal;

    my %meta := $normal;

    # fez names a tarball after its SHA-1: remember it, Core.fetch checks the download (J)
    %meta<sha1> = ~$0.lc if $!source eq 'path' and $source ~~ / ( <xdigit> ** 40 ) '.tar.gz' $ /;

    %bucket{ bucket-of %meta<name> }{ %meta<name> }.push: %meta;

    %provides{ $_ }{ %meta<name> } = True for ( %meta<provides> // {} ).keys;

  }

  my $new = $!store.add: "derived.$*PID.part";
  my $old = $!store.add: "derived.$*PID.old";

  try remove-dir $new if $new.e;

  $new.add( 'by-name' ).mkdir;

  for %bucket.kv -> $hh, %names { $new.add( 'by-name' ).add( "$hh.json" ).spurt: Rakudo::Internals::JSON.to-json: %names }

  $new.add( 'names.json' ).spurt:    Rakudo::Internals::JSON.to-json: %bucket.values.map( *.keys.Slip ).sort.List;
  $new.add( 'provides.json' ).spurt: Rakudo::Internals::JSON.to-json: %provides.map( { .key => .value.keys.sort.List } ).Hash;
  $new.add( 'format' ).spurt:        FORMAT;

  # swap: a reader sees the old files or the new ones, never a half written set
  {
    CATCH { default { log '🐞', header => 'IDX', msg => $!name, comment => "derived index not replaced: { .message }"; try remove-dir $new; return } }

    self!derived.rename( $old ) if self!derived.e;
    $new.rename: self!derived;
  }

  try remove-dir $old if $old.e;

  %!bucket = (); %!provides = (); $!names = Nil;

  $!ready = True;

  log '🐛', header => 'IDX', msg => $!name, comment => "{ %bucket.values.map( *.elems ).sum } names, { %provides.elems } units";

}

# the derived index is there and current, or is made from the stored index (offline)
method !prepare ( --> Nil ) {

  return if $!ready;

  self.refresh;

  die X::Pakku::Index.new: msg => $!name, comment => 'no local index, run: pakku refresh' unless self.index-file.e;

  my sub current ( --> Bool:D ) {
    self!format-file.e and self!format-file.slurp.trim eq FORMAT and self!names-file.e and self!units-file.e
  }

  unless current() {

    lock-file self!lock-file, {

      unless current() {

        log '🐛', header => 'IDX', msg => $!name, comment => 'deriving the index';

        my $mirror = self!mirror-file.e ?? self!mirror-file.slurp.trim !! @!mirrors.head;

        self!derive: Rakudo::Internals::JSON.from-json( self.index-file.slurp ), :$mirror;

      }

    }

  }

  $!ready = True;

}

method !json ( IO::Path:D $file ) {

  # a refresh in another process may swap the derived directory under us: one retry
  my $text = try $file.slurp;

  without $text { sleep 0.2; $text = try $file.slurp }

  $text.defined ?? ( try Rakudo::Internals::JSON.from-json: $text ) !! Nil;

}

method !load-provides ( --> Nil ) {

  $!lock.protect: { %!provides = ( self!json( self!units-file ) // {} ) unless %!provides }

}

method !names-of ( Str:D $unit ) {

  self!load-provides;

  ( %!provides{ $unit } // Empty ).List;

}

method by-name ( Str:D $name ) {

  self!prepare;

  my $hh = bucket-of $name;

  my %names := $!lock.protect: { %!bucket{ $hh } //= ( self!bucket-file( $hh ).e ?? ( self!json( self!bucket-file( $hh ) ) // {} ) !! {} ) };

  ( %names{ $name } // Empty ).List;

}

method by-provides ( Str:D $unit ) {

  self!prepare;

  self!names-of( $unit ).map( { self.by-name( $_ ).grep( -> %meta { ( %meta<provides> // {} ){ $unit }:exists } ).Slip } ).List;

}

method names ( ) {

  self!prepare;

  $!lock.protect: { $!names //= ( self!json( self!names-file ) // [] ).List };

}

method units ( ) {

  self!prepare;

  self!load-provides;

  %!provides.keys.List;

}

# a miss on an index older than ten minutes is worth one refresh: the dist may be brand new
method refresh-on-miss ( Pakku::Spec::Raku:D :$spec! ) {

  return Nil if $!refresh === False or self.age < 600;

  return Nil unless self.refresh: :force;

  self.lookup: :$spec;

}
