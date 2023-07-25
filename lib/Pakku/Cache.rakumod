use nqp;

use Pakku::Log;

use Pakku::Spec;
use Pakku::Meta;

unit class Pakku::Cache;

has IO::Path() $!cache is built;

method recommend ( Pakku::Spec::Raku:D :$spec! ) {

  🐛 qq[CAC: ｢$spec｣ recommending...];

  my $name-hash = nqp::sha1( $spec.name );

  my $spec-dir = $!cache.add: $name-hash;

  return unless $spec-dir.d;

  dir $spec-dir
    ==> grep( *.IO.d )
    ==> map(  -> $dir  { try Pakku::Meta.new: $dir } )
    ==> grep( -> $meta { $meta.meta ~~ $spec       } )
    ==> my @candy;

  return unless @candy;

  my $candy = @candy.reduce( &reduce-latest );

  🐛 qq[CAC: ｢$candy｣];

  $candy;

}

method cached ( Pakku::Meta:D :$meta! ) {

  🐛 qq[CAC: ｢$meta｣ looking...];

  my $name-hash = nqp::sha1( $meta.name );

  my $cached = $!cache.add( $name-hash ).add( $meta.id );

  if $cached.d {

    🐛 qq[CAC: ｢$meta｣ ‹$cached›];

    $cached
  }

}

method cache ( IO::Path:D :$path! ) {

  my $meta = Pakku::Meta.new: $path;

  🐛 qq[CAC: ｢$meta｣ caching...];

  my $name-hash = nqp::sha1( $meta.name );

  my $dst = $!cache.add( $name-hash ).add( $meta.id );

  copy-dir src => $path, :$dst;

  🐛 qq[CAC: ｢$meta｣ ‹$dst›];

}

sub reduce-latest ( $left, $right ) {

  my $left-ver  = $left.meta<ver>;
  my $left-api  = $left.meta<api>;
  my $right-ver = $right.meta<ver>;
  my $right-api = $right.meta<api>;

  return $left if Version.new( $left-ver // '' ) > Version.new( $right-ver // '' );
  return $left if Version.new( $left-api // '' ) > Version.new( $right-api // '' );
  return $right;
}

my sub copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst --> Nil) {

  my $relpath := $src.chars;

  for Rakudo::Internals.DIR-RECURSE( ~$src ) -> $path {

    my $destination := $dst.add( $path.substr( $relpath ) );

    $destination.parent.mkdir;

    $path.IO.copy: $destination;

  }
}


