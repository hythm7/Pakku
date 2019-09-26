use Pakku::Log;
use Pakku::Dist::Path;

unit class Pakku::Builder;


method build ( Pakku::Dist::Path:D :$dist ) {

  🐛 "Build: Processing [$dist]";

  given $dist.builder {

    when Distribution::Builder::MakeFromJSON {

      🐛 "Build: Builder is  [{.^name}]";
      .new( meta => $dist.meta ).build: $dist.prefix;

    }

    default {


      🐛 "Build: Looking for default build file";

      my $build-file =  < Build.rakumod Build.pm6 Build.pm >.first( -> $file { 

        $dist.prefix.add( $file ).f;

        } );

        unless $build-file {

          🐛 "Build: [$dist] has no build file";

          return True;

        }


        my $build = $dist.prefix.add: $build-file;

        🐛 "Build: Building [$dist] with build file [$build]";

        indir $dist.prefix, {
          require $build;
          ::('Build').new.build($dist.prefix.Str);
        }
    }

  }
}
