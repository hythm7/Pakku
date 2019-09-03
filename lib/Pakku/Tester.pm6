use Concurrent::File::Find;
use Pakku::Distribution;

unit class Pakku::Tester;

method test ( Pakku::Distribution:D :$dist ) {

  my @test = find $dist.prefix.add( 't' ).Str, :extension<t>;

  my @exitcode = @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test;

      whenever $proc.stdout.lines { ; }
      whenever $proc.stderr.lines { ; }
      whenever $proc.start( cwd => $dist.prefix ) { $exitcode = .exitcode }

    }

    $exitcode;

  });

  fail "Test failed for {$dist.name}" if  any @exitcode;

}
