
use Pakku::Log;

use Pakku::Spec;
use Pakku::Meta;

unit class Pakku::Cache;

has IO::Path() $.cache-dir;

method recommend ( Pakku::Spec::Raku:D :$spec! ) {

  log '🐛', header => 'CAC', msg => ~$spec, :comment<recommending!>;

  my $name-hash = sha1 $spec.name;

  my $spec-dir = $!cache-dir.add: $name-hash;

  return unless $spec-dir.d;

  dir $spec-dir
    ==> grep( *.IO.d )
    ==> map(  -> $dir  { try Pakku::Meta.new: $dir } )
    ==> grep( -> $meta { $meta.meta ~~ $spec       } )
    ==> my @candy;

  return unless @candy;

  my $candy = @candy.reduce( &reduce-latest );

  log '🐛', header => 'CAC', msg => ~$candy;

  $candy;

}

method cached ( Pakku::Meta:D :$meta! ) {

  log '🐛', header => 'CAC', msg => ~$meta, :comment<looking!>;

  my $name-hash = sha1( $meta.name );

  my $cached = $!cache-dir.add( $name-hash ).add( $meta.id );

  if $cached.d {

    log '🐛', header => 'CAC', msg => ~$meta, comment => ~$cached;

    $cached
  }

}

method cache ( IO::Path:D :$path! ) {

  my $meta = Pakku::Meta.new: $path;

  log '🐛', header => 'CAC', msg => ~$meta, :comment<caching!>;

  my $name-hash = sha1( $meta.name );

  my $dst = $!cache-dir.add( $name-hash ).add( $meta.id );

  copy-dir src => $path, :$dst;

  log '🐛', header => 'CAC', msg => ~$meta, comment => ~$dst;

}

multi reduce-latest ( $left ) { $left }

multi reduce-latest ( $left, $right ) {

  my $left-ver  = $left.meta<ver>;
  my $left-api  = $left.meta<api>;
  my $right-ver = $right.meta<ver>;
  my $right-api = $right.meta<api>;

  return $left if Version.new( $left-ver // '' ) > Version.new( $right-ver // '' );
  return $left if Version.new( $left-api // '' ) > Version.new( $right-api // '' );

  $right;
}

my sub copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst --> Nil) {

  my $relpath := $src.chars;

  for Rakudo::Internals.DIR-RECURSE( ~$src ) -> $path {

    my $destination := $dst.add( $path.substr( $relpath ) );

    $destination.parent.mkdir;

    $path.IO.copy: $destination;

  }
}

my sub sha1 ( $what ) { use nqp; nqp::sha1( $what ) }
