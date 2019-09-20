use Pakku::Log;
use Pakku::Dist::Path;

unit class Pakku::Builder;


method build ( Pakku::Dist::Path:D :$dist ) {

  D "Building $dist";

  given $dist.builder {

    when Distribution::Builder::MakeFromJSON {

      .new( meta => $dist.meta ).build: $dist.prefix;

    }

    default {

      my $build =  $dist.prefix.add: 'Build.pm';

      if $build.f {

        require $build;
        ::('Build').new.build($dist.prefix.Str);

      }

      return True;
    }

  }
}
