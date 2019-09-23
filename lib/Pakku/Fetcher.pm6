use Cro::Uri;
use File::Temp;
use LibCurl::Easy;
use Libarchive::Simple;

use Pakku::Log;

unit class Pakku::Fetcher;

method fetch ( Str :$src!, :$dst = tempdir ) {

  D "Fetch: Fetching $src to $dst";

  my $uri = Cro::Uri.parse: $src;

  given $uri {

    when .path.IO.extension ~~ any('git', '') {

      #run 'git', 'clone', $src, cwd => $dst, :!out, :!err;
      #
      D "Fetch: Cloning git repo [$src]";

      my $url = S/^git/https/ with $src;

      my $proc = run 'git', 'clone', $url, cwd => $dst, :out, :err;

      T $proc.out.slurp(:close);
      T $proc.err.slurp(:close);

      my $dist-path = $dst.IO.dir.first: *.d;

      D "Fetch: Dist path is [$dist-path]";

      $dist-path;

    }

    default {

      my $download = $dst.IO.add( $uri.path.IO.basename ).Str;

      D "Fetch: Downloading url [$src] to [$download]";

      LibCurl::Easy.new( URL => $uri.Str, :$download ).perform;

      D "Fetch: Extracting [$download]";

      .extract: destpath => $dst for archive-read $download;

      my $dist-path = $dst.IO.dir.first: *.d;

      D "Fetch: Dist path is [$dist-path]";

      $dist-path;

    }

  }

}
