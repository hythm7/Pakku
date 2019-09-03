use Cro::Uri;
use File::Temp;
use LibCurl::Easy;
use Libarchive::Simple;

unit class Pakku::Fetcher;


method fetch ( :$src!, :$dst = tempdir ) {

  my $uri = Cro::Uri.parse: $src;

  given $uri {

    when .path.IO.extension ~~ any('git', '') {

      #run 'git', 'clone', $src, cwd => $dst, :!out, :!err;
      #
      my $url = S/git/https/ with $src;
      run 'git', 'clone', $url, cwd => $dst, :!out, :!err;

      $dst.IO.dir.first: *.d;

    }

    default {

      my $download = $dst.IO.add( $uri.path.IO.basename ).Str;

      LibCurl::Easy.new( URL => $uri.Str, :$download ).perform;

      .extract: destpath => $dst for archive-read $download;

      $dst.IO.dir.first: *.d;

    }

  }

}
