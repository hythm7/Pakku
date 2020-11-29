use File::Find;

use Pakku::Log;
use X::Pakku::Test;

unit role Pakku::Tester;

method test ( Distribution::Locally:D :$dist! ) {

  <tests t>
    ==> map( -> $dir { $dist.prefix.add: $dir }  )
    ==> grep( *.d )
    ==> map( -> $dir { find :$dir, name => / '.' < t rakutest > $ / } )
    ==> flat()
    ==> my @test;

  return unless @test;

  🐞 "TST: ｢$dist｣";



  my $prefix  = $dist.prefix;
  my $lib     = $prefix.add: <lib>;
  my $include = "$lib,{ $*repo.head.path-spec }";

  #  my @deps    = $dist.deps( :$!deps ).grep( { .from ~~ 'raku' } );

  @test.map( -> $test {

    🐞 "TST: ｢{$test.basename}｣";

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, '-I', $include, $test.relative: $prefix;

      whenever $proc.stdout.lines { 🤓 $^out }
      whenever $proc.stderr.lines { 🔔 $^err }

      whenever $proc.stdout.stable( 420 ) {

        🔔 "TOT: ｢$dist｣";

        $proc.kill;

        $exitcode = 1;

        done;

      }

      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        $exitcode = .exitcode;
        done;

      }


    }

    die X::Pakku::Test.new: :$dist if $exitcode;

  });


  🦋 "TST: ｢$dist｣";

}
