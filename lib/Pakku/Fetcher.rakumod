use URL;
use File::Temp;
use LibCurl::Easy;
use Libarchive::Simple;

use Pakku::Log;

unit class Pakku::Fetcher;

multi method fetch ( Str $src!, :$unlink = True, :$dst = tempdir :$unlink ) {

  🤓 "FTC: ｢$src｣";

  my $uri = URL.new: $src;

  my $download = $dst.IO.add( $uri.path.tail ).Str;


  LibCurl::Easy.new( URL => $uri.Str, :$download, :followlocation ).perform;


  .extract: destpath => $dst for archive-read $download;

  my $prefix = $dst.IO.dir.first: *.d;

  🤓 "FTC: ｢$prefix｣";

  $prefix.IO;

}

multi method fetch ( IO $src! ) { $src }
