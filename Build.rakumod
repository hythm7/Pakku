unit class Build;

has $.dist-path;

method build ( IO( ) $dist-path --> True ) {

  my $ecosystem-src = 'https://raw.githubusercontent.com/hythm7/raku-ecosystem/master/resources/ecosystem.json';
  my $ecosystem-dst = $dist-path.add: 'resources/ecosystem.json';

  run 'curl', $ecosystem-src, '--output', $ecosystem-dst, :out, :err;

}
