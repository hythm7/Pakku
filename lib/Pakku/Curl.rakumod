use NativeCall;

use X::Pakku;
use Pakku::Log;
use Pakku::Native;

# Minimal libcurl easy-API binding: download one URL to one file.
# The library is resolved lazily (first call), so Pakku loads fine on a
# machine without libcurl and Pakku::Fetch can fall back to the curl binary.
unit class Pakku::Curl;

constant IS-WIN = Rakudo::Internals.IS-WIN();

constant CURLOPT_WRITEDATA        = 10001;
constant CURLOPT_URL              = 10002;
constant CURLOPT_USERAGENT        = 10018;
constant CURLOPT_ACCEPT_ENCODING  = 10102;
constant CURLOPT_TIMEOUT          = 13;
constant CURLOPT_LOW_SPEED_LIMIT  = 19;
constant CURLOPT_LOW_SPEED_TIME   = 20;
constant CURLOPT_NOPROGRESS       = 43;
constant CURLOPT_FAILONERROR      = 45;
constant CURLOPT_FOLLOWLOCATION   = 52;
constant CURLOPT_MAXREDIRS        = 68;
constant CURLOPT_CONNECTTIMEOUT   = 78;
constant CURLOPT_NOSIGNAL         = 99;
constant CURLOPT_PROTOCOLS        = 181;
constant CURLOPT_XFERINFOFUNCTION = 20219;
constant CURLINFO_RESPONSE_CODE   = 0x200002;
constant CURLPROTO_HTTP_HTTPS     = 1 +| 2;
constant CURL_GLOBAL_DEFAULT      = 3;

class CURL is repr('CPointer') { }
class FILE is repr('CPointer') { }

my sub lib ( --> Str:D ) {

  state $lib = (
    $*VM.platform-library-name( 'curl'.IO, version => v4 ).Str,
    $*VM.platform-library-name( 'curl'.IO               ).Str,
  ).first( -> $lib { Pakku::Native.can-load: $lib } );

  $lib // die X::Pakku::Native.new: msg => 'libcurl', comment => 'not found!';

}

sub fopen  ( Str, Str --> FILE  ) is native { * }
sub fclose ( FILE     --> int32 ) is native { * }

sub curl_global_init   ( long --> int32 ) is native( &lib ) { * }
sub curl_version       (      --> Str   ) is native( &lib ) { * }
sub curl_easy_init     (      --> CURL  ) is native( &lib ) { * }
sub curl_easy_cleanup  ( CURL           ) is native( &lib ) { * }
sub curl_easy_perform  ( CURL --> int32 ) is native( &lib ) { * }
sub curl_easy_strerror ( int32 --> Str  ) is native( &lib ) { * }

sub curl_easy_setopt_str  ( CURL, int32, Str   --> int32 ) is native( &lib ) is symbol( 'curl_easy_setopt' ) { * }
sub curl_easy_setopt_long ( CURL, int32, long  --> int32 ) is native( &lib ) is symbol( 'curl_easy_setopt' ) { * }
sub curl_easy_setopt_file ( CURL, int32, FILE  --> int32 ) is native( &lib ) is symbol( 'curl_easy_setopt' ) { * }
sub curl_easy_setopt_xfer ( CURL, int32, &cb ( Pointer, int64, int64, int64, int64 --> int32 ) --> int32 ) is native( &lib ) is symbol( 'curl_easy_setopt' ) { * }

sub curl_easy_getinfo_long ( CURL, int32, int64 is rw --> int32 ) is native( &lib ) is symbol( 'curl_easy_getinfo' ) { * }

my Lock $init-lock .= new;
my Bool $initialized = False;

# Windows ships curl.exe but no libcurl.dll (and a foreign libcurl would not
# share our C runtime's FILE*), so the binding is POSIX only.
method available ( ::?CLASS:U: --> Bool:D ) {

  return False if IS-WIN;

  so try lib;

}

method version ( ::?CLASS:U: --> Str:D ) { curl_version }

method download (
  ::?CLASS:U:
  Str:D      :$url!,
  IO::Path:D :$dst!,
  Int:D      :$timeout = 300,
  Int:D      :$connect-timeout = 30,
  Str:D      :$agent = 'Pakku',
  Bool:D     :$progress = False,
  --> IO::Path:D
) {

  $init-lock.protect: { unless $initialized { curl_global_init( CURL_GLOBAL_DEFAULT ); $initialized = True } }

  my $fh = fopen( ~$dst, 'wb' );

  die X::Pakku::Fetch.new: msg => ~$dst, comment => 'can not open for writing!' unless $fh;

  my $curl = curl_easy_init;

  unless $curl {
    fclose $fh;
    die X::Pakku::Fetch.new: msg => $url, comment => 'curl_easy_init failed!';
  }

  my &xfer = sub ( Pointer $u, int64 $dltotal, int64 $dlnow, int64 $ultotal, int64 $ulnow --> int32 ) {
    if $dltotal > 0 { bar.percent: $dlnow * 100 div $dltotal; bar.show }
    0
  }

  curl_easy_setopt_str(  $curl, CURLOPT_URL,              $url );
  curl_easy_setopt_str(  $curl, CURLOPT_USERAGENT,        $agent );
  curl_easy_setopt_str(  $curl, CURLOPT_ACCEPT_ENCODING,  '' );
  curl_easy_setopt_long( $curl, CURLOPT_FOLLOWLOCATION,   1 );
  curl_easy_setopt_long( $curl, CURLOPT_MAXREDIRS,        10 );
  curl_easy_setopt_long( $curl, CURLOPT_FAILONERROR,      1 );
  curl_easy_setopt_long( $curl, CURLOPT_NOSIGNAL,         1 );
  curl_easy_setopt_long( $curl, CURLOPT_PROTOCOLS,        CURLPROTO_HTTP_HTTPS );
  curl_easy_setopt_long( $curl, CURLOPT_CONNECTTIMEOUT,   $connect-timeout );
  curl_easy_setopt_long( $curl, CURLOPT_TIMEOUT,          $timeout );
  curl_easy_setopt_long( $curl, CURLOPT_LOW_SPEED_LIMIT,  1 );
  curl_easy_setopt_long( $curl, CURLOPT_LOW_SPEED_TIME,   60 );
  curl_easy_setopt_file( $curl, CURLOPT_WRITEDATA,        $fh );

  if $progress {
    bar.header: 'FTC';
    bar.length: $url.IO.basename.chars;
    bar.sym:    $url.IO.basename;
    bar.activate;
    curl_easy_setopt_long( $curl, CURLOPT_NOPROGRESS, 0 );
    curl_easy_setopt_xfer( $curl, CURLOPT_XFERINFOFUNCTION, &xfer );
  }

  my $rc = curl_easy_perform( $curl );

  my int64 $code = 0;

  curl_easy_getinfo_long( $curl, CURLINFO_RESPONSE_CODE, $code );

  curl_easy_cleanup( $curl );

  fclose( $fh );

  bar.deactivate if $progress;

  die X::Pakku::Fetch.new: msg => $url, comment => "curl: ($rc) " ~ curl_easy_strerror( $rc ) ~ ( " HTTP $code" if $code ) if $rc;

  $dst;

}
