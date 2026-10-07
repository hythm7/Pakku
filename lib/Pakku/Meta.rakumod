use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Util;
use Pakku::Collapse;

# A distribution's META, with its dependencies as Pakku::Spec objects.
# S22 by-* switches are collapsed once, at construction.
unit class Pakku::Meta;

has %.meta;

has Str $.dist   is built( False );
has Str $.id     is built( False );
has Str $.name   is built( False );

has $.source is built( False );

has %!deps;   # phase => level => [ raw dependency values ]

method to-json ( ) { Rakudo::Internals::JSON.to-json: %!meta }

method ver  ( ) { %!meta<ver> // %!meta<version> }
method api  ( ) { %!meta<api>  }
method auth ( ) { %!meta<auth> }

multi method Str ( ::?CLASS:D: --> Str:D ) { $!dist }

# hard dependencies are the "requires" of a phase; recommends/suggests are informational
multi method deps ( ) { %!deps }

multi method deps ( Bool:D :$deps where *.so ) { self!specs: <build test runtime> }

multi method deps ( Str:D :$deps where 'runtime' | 'test' | 'build' ) { self!specs: $deps }

multi method deps ( Str:D :$deps where 'only' ) { samewith :deps }

multi method deps ( Bool:D :$deps where not *.so ) { Empty }

multi method deps ( :$deps! ) { die X::Pakku::Meta.new: msg => $!dist, comment => "unknown deps value '$deps'!" }

method recommends ( ) { self!specs: <build test runtime>, level => 'recommends' }

method !specs ( *@phase, Str:D :$level = 'requires' ) {

  @phase
    ==> map( { ( %!deps{ $_ }{ $level } // [] ).Slip } )
    ==> map( { Pakku::Spec.new: $_ } )
    ==> unique( as => *.Str );

}

method to-dist ( ::?CLASS:D: IO::Path:D $prefix! ) {

  # %bins and resources stolen from Rakudo
  my %bins = Rakudo::Internals.DIR-RECURSE($prefix.add('bin').absolute).map(*.IO).map: -> $real-path {
    my $name-path = $real-path.is-relative
      ?? $real-path
      !! $real-path.relative($prefix);
    $name-path.subst(:g, '\\', '/') => $name-path.subst(:g, '\\', '/')
  }

  my $resources-dir = $prefix.add('resources');
  my %resources = %!meta<resources>.grep(*.?chars).map(*.IO).map: -> $path {
    my $real-path = $path ~~ m/^libraries\/(.*)/
        ?? $resources-dir.add('libraries').add( $*VM.platform-library-name($0.Str.IO) )
        !! $resources-dir.add($path);
    my $name-path = $path.is-relative
        ?? "resources/{$path}"
        !! "resources/{$path.relative($prefix)}";
    $name-path.subst(:g, '\\', '/') => $real-path.relative($prefix).subst(:g, '\\', '/')
  }

  %!meta<files> = Hash.new(%bins, %resources);

  self does Distribution::Locally( :$prefix );

}

submethod TWEAK ( ) {

  $!name = %!meta<name> // die X::Pakku::Meta.new: msg => ( %!meta<dist> // %!meta.raku.substr( 0, 60 ) ), comment => 'no name in META!';

  $!dist = quietly "{ $!name }:ver<{ self.ver }>:auth<{ %!meta<auth> }>:api<{ %!meta<api> }>";

  $!id = sha1 $!dist;

  $!source = %!meta<source>;

  # deprecated top-level lists (S22) are build / test requires
  with %!meta<build-depends> { self!add: 'build', $_ }
  with %!meta<test-depends>  { self!add: 'test',  $_ }

  given %!meta<depends> {

    when Positional  { self!add: 'runtime', $_ }

    when Associative { for <runtime test build> -> $phase { with .{ $phase } { self!add: $phase, $_ } } }

  }

}

method !add ( Str:D $phase, $deps ) {

  given $deps {

    when Positional  { %!deps{ $phase }<requires>.append: .List }

    when Associative { for <requires recommends suggests> -> $level { with .{ $level } { %!deps{ $phase }{ $level }.append: .List } } }

    default { die X::Pakku::Meta.new: msg => $!dist, comment => "$phase dependencies must be a list or an object!" }

  }

}

multi method gist ( ::?CLASS:D: Bool:D :$details --> Str:D ) {

  return color( "｢{ self }｣", magenta ) unless $details;

  my Str $info = color( "MTA: ｢{ self }｣", magenta );

  $info ~= self.deps( :deps ).sort( *.Str ).map( -> $dep { "\n" ~ color( "DEP: ｢$dep｣", cyan ) } ).join;

  $info ~= .keys.sort.map( -> $provide { "\n" ~ color( "PRV: ｢$provide｣", green ) } ).join with %!meta<provides>;

  $info ~= "\n" ~ color( "URL: ｢{ .Str }｣", blue  ) with %!meta<source-url>;
  $info ~= "\n" ~ color( "SRC: ｢{ .Str }｣", blue  ) with %!meta<source>;
  $info ~= "\n" ~ color( "REC: ｢{ .Str }｣", blue  ) with %!meta<recman>;
  $info ~= "\n" ~ color( "DES: ｢{ .Str }｣", white ) with %!meta<description>;

  $info;

}

proto method new ( | ) { * };

multi method new ( Str:D $json ) {

  my $meta = try Rakudo::Internals::JSON.from-json: $json;

  die X::Pakku::Meta.new: msg => $json.substr( 0, 60 ), comment => 'invalid JSON!' unless $meta ~~ Associative;

  samewith $meta;

}

multi method new ( IO::Path:D $path ) {

  my $meta-file = meta-file $path;

  die X::Pakku::Meta.new: msg => ~$path, comment => 'no META6.json!' unless $meta-file;

  my $meta = try Rakudo::Internals::JSON.from-json: $meta-file.slurp;

  die X::Pakku::Meta.new: msg => ~$meta-file, comment => 'invalid JSON!' unless $meta ~~ Associative;

  samewith $meta;

}

multi method new ( %meta ) {

  self.bless: meta => collapse( %meta, dist => ~( %meta<dist> // %meta<name> // '?' ) );

}

# newest first: version, then api, then release-date (REA), then a zef: auth, then auth name
sub latest-first ( $a, $b --> Order:D ) is export {

  my %a := $a ~~ Pakku::Meta ?? $a.meta !! $a;
  my %b := $b ~~ Pakku::Meta ?? $b.meta !! $b;

  ( version( %b<ver> // %b<version> ) cmp version( %a<ver> // %a<version> ) )
  || ( version( %b<api> ) cmp version( %a<api> ) )
  || ( ( %b<release-date> // '' ) cmp ( %a<release-date> // '' ) )
  || ( ( %b<auth> // '' ).starts-with( 'zef:' ) <=> ( %a<auth> // '' ).starts-with( 'zef:' ) )
  || ( ( %a<auth> // '' ) cmp ( %b<auth> // '' ) );

}

sub latest ( @meta ) is export { @meta.sort( &latest-first ).head }
