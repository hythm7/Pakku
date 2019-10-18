use Pakku::Log;
use Pakku::Dist::Perl6::Path;

unit class Pakku::Builder;


# TODO: Timeout
method build ( Pakku::Dist::Perl6::Path:D :$dist ) {

  🐛 "Build: Processing [$dist]";

  given $dist.builder {

    when Distribution::Builder::MakeFromJSON {

      🐛 "Build: Builder is  [{.^name}]";
      .new( meta => $dist.meta ).build: $dist.prefix;

      CATCH {

        default {

          die X::Pakku::Build::Fail.new: :$dist;

        }
      }

    }

    default {


      🐛 "Build: Looking for build file";

      my @build-file =  < Build.rakumod Build.pm6 Build.pm >;

      my $build-file = @build-file.map( -> $f { $dist.prefix.add: $f } ).first( *.f );

      unless $build-file {

        🐛 "Build: No build file for dist [$dist]";

        return;

      }

      🐛 "Build: Building [$dist] with build file [$build-file]";

        my $dist-dir  = $dist.prefix;
        my $lib-dir   = $dist-dir.add: 'lib';
        my $include   = "-I $lib-dir";
        my $execute   = "-e";
        my $build-cmd = qq:to/CMD/;
        require "$build-file";
        ::( 'Build' ).new.build( "$dist-dir" );
        CMD

        my $proc = run ~$*EXECUTABLE, $include, $execute, $build-cmd, cwd => $dist-dir, :out, :err;
        $proc.out.lines.map( 👣 * );
        $proc.err.lines.map( ✗  * );

        die X::Pakku::Build::Fail.new: :$dist if $proc.exitcode;
    }


  }

  🐛 "Build: Built [$dist]";
}
