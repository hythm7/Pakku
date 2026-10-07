use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Build;

multi method fly ( 'build', IO::Path:D :$path! is copy, Int :$timeout ) {

  log '🧚', header => 'BLD', msg => ~$path;

  $path = self!dist-path: $path;

  my $meta = Pakku::Meta.new: $path;

  self!try-out: $meta, dist => $meta.to-dist( $path ), :!build-target, -> $stage, $dist { self.build: :$stage, :$dist };

}

multi method fly ( 'build', Str:D :$spec!, Int :$timeout ) {

  log '🧚', header => 'BLD', msg => ~$spec;

  my $meta = self.satisfy: spec => Pakku::Spec.new: $spec;

  return without $meta;

  self!try-out: $meta, :!build-target, -> $stage, $dist { self.build: :$stage, :$dist };

}
