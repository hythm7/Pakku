use Pakku::Log;
use X::Pakku::Test;

unit role Pakku::Test;

method test ( Distribution::Locally:D :$dist! ) {

  <tests t>
    ==> map( -> $dir { $dist.prefix.add: $dir }  )
    ==> grep( *.d )
    ==> map( -> $dir { find-tests :$dir } )
    ==> flat()
    ==> my @test;

  return unless @test;

  🐞 "TST: ｢$dist｣";



  my $prefix  = $dist.prefix;
  my $lib     = $prefix.add: <lib>;
  my $include = "$lib,{ $*repo.path-spec }";

  #  my @deps    = $dist.deps( :$!deps ).grep( { .from ~~ 'raku' } );

  @test.map( -> $test {

    🐞 "TST: ｢{$test.basename}｣";

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, '-I', $include, $test.relative: $prefix;

      whenever $proc.stdout.lines { 🤓 ( 'TST: ' ~ $^out ) }
      whenever $proc.stderr.lines { ❌ ( 'TST: ' ~ $^err ) }

      whenever $proc.stdout.stable( 42 ) {

      🐞 "WAI: ｢{$proc.command}｣";

      }

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

sub find-tests ( IO::Path:D :$dir! ) {

  my @test;

  my @stack = $dir;

  while @stack {

    with @stack.pop {
        when :d { @stack.append: .dir }
        @test.push: .self when .extension.lc ~~ any <rakutest t>;
    }
  }

  @test;
}

