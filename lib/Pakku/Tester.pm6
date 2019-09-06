use Concurrent::File::Find;

use Pakku::Distribution;

unit class Pakku::Tester;

has $.log;


method test ( Pakku::Distribution:D :$dist ) {



  my $test-dir = $dist.prefix.add( 't' );

  return unless $test-dir.d;

  my @test = find $test-dir.Str, :extension<t>;

  $!log.debug: "Testing $dist" if @test;

  my @exitcode = @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test;

      whenever $proc.stdout.lines { $!log.trace: $^out }
      whenever $proc.stderr.lines { $!log.trace: $^err }
      whenever $proc.start( cwd => $dist.prefix ) { $exitcode = .exitcode }

    }

    $exitcode;

  });

  $!log.fatal: "Test failed for {$dist.name}" if  any @exitcode;

}
