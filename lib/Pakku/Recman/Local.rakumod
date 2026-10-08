use Pakku::Log;
use Pakku::Meta;
use Pakku::Util;
use Pakku::Recman::Index;

# A directory of extracted distributions (each in its own sub-directory).
unit class Pakku::Recman::Local;
  also does Pakku::Recman::Index;

has IO::Path:D() $.location is required;

has %!meta;       # dist name => [ metas ]
has %!provides;   # unit      => [ metas ]

method by-name     ( Str:D $name ) { ( %!meta{ $name }     // Empty ).List }
method by-provides ( Str:D $unit ) { ( %!provides{ $unit } // Empty ).List }
method names       ( )             { %!meta.keys.List }
method units       ( )             { %!provides.keys.List }

submethod TWEAK ( ) {

  unless $!location.d {
    log '🐞', header => 'REC', msg => ~$!name, comment => "$!location: does not exist!";
    return;
  }

  for $!location.dir.grep( *.d ).sort -> $dir {

    my $meta-file = meta-file $dir;

    unless $meta-file {
      log '🐞', header => 'REC', msg => ~$!name, comment => "$dir: no META6.json!";
      next;
    }

    my $raw = try Rakudo::Internals::JSON.from-json: $meta-file.slurp;

    unless $raw ~~ Associative and $raw<name> {
      log '🐞', header => 'REC', msg => ~$!name, comment => "$meta-file: invalid META!";
      next;
    }

    my $normal = self.normalise( $raw, source => $dir );

    next without $normal;

    my %meta := $normal;

    %!meta{ %meta<name> }.push: %meta;

    %!provides{ $_ }.push: %meta for ( %meta<provides> // {} ).keys;

  }

}
