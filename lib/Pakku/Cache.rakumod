
use Pakku::Log;
use Pakku::Util;
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

  my $candy = latest @candy;

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

