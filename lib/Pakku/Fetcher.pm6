use Cro::Uri;
use File::Temp;
use LibCurl::Easy;
use Libarchive::Simple;

unit role Pakku::Fetcher;


method fetch ( :$src!, :$dst = tempdir ) {

  my $uri = Cro::Uri.parse-ref: $src;

  given $uri {

    when .scheme.so and .path.IO.extension ~~ any('git', '') {

      run 'git', 'clone', $src, cwd => $dst, :!out, :!err;
      
      $dst.IO.dir.first: *.d;
    } 

    when .scheme.so {
      
      my $download = $dst.IO.add( $uri.path.IO.basename ).Str;

      LibCurl::Easy.new( URL => $uri.Str, :$download ).perform;

      .extract: destpath => $dst for archive-read $download;
      
      $dst.IO.dir.first: *.d;
    }

    when not .scheme.so {

     $src.IO; 

    }
  }

}
