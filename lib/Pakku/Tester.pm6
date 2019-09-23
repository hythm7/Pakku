use Concurrent::File::Find;

use Pakku::Log;
use Pakku::Dist;

unit class Pakku::Tester;



method test ( Pakku::Dist:D :$dist ) {


  my $test-dir = $dist.prefix.add( 't' );

  return unless $test-dir.d;

  my $lib-dir = $dist.prefix.add( 'lib' );
  my $include = "-I $lib-dir";

  my @test = find $test-dir.Str, :extension<t>;

  D "Testing $dist" if @test;

  my @exitcode = @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $include, $test;

      whenever $proc.stdout.lines { T $^out }
      whenever $proc.stderr.lines { ✗ $^err }
      whenever $proc.start( cwd => $dist.prefix ) { $exitcode = .exitcode }

    }

    $exitcode;

  });

  ☠ "Test failed for {$dist.name}" if  any @exitcode;

}
