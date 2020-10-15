use File::Find;

use Pakku::Log;
use X::Pakku::Test;

unit role Pakku::Tester;

# TODO: Timeout
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
  # BUG: Applies only to custom path inst#
     # including $*repo messes up %?RESOURCES
     # And distributions like Test::META (which depends
     # on License::SPDX) doesn't pass the testing phase
     # Because License::SPDX's %?RESOURCES becomes empty
  my $include = "-I$lib,{ $*repo.head.path-spec }";

  #  my @deps    = $dist.deps( :$!deps ).grep( { .from ~~ 'raku' } );

  @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $include, $test.IO.relative: $prefix;

      whenever $proc.stdout.lines { 🤓 $^out }
      whenever $proc.stderr.lines { 🔔 $^err }

      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        $exitcode = .exitcode;
        done;

      }

    }

    die X::Pakku::Test.new: :$dist if $exitcode;

  });


  🦋 "TST: ｢$dist｣";

}
