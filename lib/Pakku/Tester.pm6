use Concurrent::File::Find;

use Pakku::Log;
use Pakku::Dist::Perl6;

unit class Pakku::Tester;

# TODO: Timeout
method test ( Pakku::Dist::Perl6:D :$dist!, :$repo ) {

  my @test-dir  = < tests    t >;
  my @extension = < rakutest t >;

  my @test
    <== flat()
    <== map( -> $dir { find ~$dir, :@extension } )
    <== grep( *.d )
    <== map( -> $dir { $dist.prefix.add: $dir }  )
    <== @test-dir;

  unless @test {

    🐛 "Test: No tests for dist [$dist]";

    return;

  }

  🐛 "Testing $dist" if @test;

  my $dist-dir = $dist.prefix;
  my $lib-dir  = $dist-dir.add: 'lib';
  my $include  = $repo ?? "-I $lib-dir,{$repo.path-spec}" !! "-I $lib-dir";

  my @exitcode = @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $include, $test.IO.relative: $dist-dir;

      whenever $proc.stdout.lines { 👣 $^out }
      whenever $proc.stderr.lines { ✗ $^err }
      whenever $proc.start( cwd => $dist-dir, :%*ENV ) { $exitcode = .exitcode }

    }

    $exitcode;

  });

  die X::Pakku::Test::Fail.new: :$dist if any @exitcode;

}
