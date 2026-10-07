use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Test;

multi method fly ( 'test', IO::Path:D :$path!, Bool:D :$xtest = False, Bool:D :$build = True, Int :$timeout ) {

  log '🧚', header => 'TST', msg => ~$path;

  my $meta = Pakku::Meta.new: $path;

  self!try-out: $meta, dist => $meta.to-dist( $path ), :$build, -> $stage, $dist { self.test: :$stage, :$dist, :$xtest };

}

multi method fly ( 'test', Str:D :$spec!, Bool:D :$xtest = False, Bool:D :$build = True, Int :$timeout ) {

  log '🧚', header => 'TST', msg => ~$spec;

  my $meta = self.satisfy: spec => Pakku::Spec.new: $spec;

  return without $meta;

  self!try-out: $meta, :$build, -> $stage, $dist { self.test: :$stage, :$dist, :$xtest };

}
