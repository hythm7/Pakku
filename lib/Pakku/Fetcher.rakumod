use URL;
use Retry;
use File::Temp;
use LibCurl::Easy;
use Libarchive::Simple;

use Pakku::Log;

unit class Pakku::Fetcher;

has $!curl = LibCurl::Easy.new;

multi method fetch ( Str $src!, :$unlink = True, :$dst = tempdir :$unlink ) {

  🤓 "FTC: ｢$src｣";

  my $URL = URL.new: $src;

  my $download = $dst.IO.add( $URL.path.tail ).Str;

  $!curl.setopt: URL => $URL.Str, :$download;

  retry { $!curl.perform };

  .extract: destpath => $dst for archive-read $download;

  my $prefix = $dst.IO.dir.first: *.d;

  🤓 "FTC: ｢$prefix｣";

  $prefix.IO;

}

multi method fetch ( IO $src! ) { $src }
