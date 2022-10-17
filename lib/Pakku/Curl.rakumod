use NativeCall;

use Pakku::Native;

### Stolen from LibCurl:auth<github:CurtTilmes> 

BEGIN my $lib     = 'curl';
BEGIN my $version = v4;

constant  LIB = (
  $*VM.platform-library-name( $lib.IO, :$version ).Str,
  $*VM.platform-library-name( $lib.IO            ).Str,
).first( -> \lib { Pakku::Native.can-load: lib } );

constant CURLE_OK = 0;

class Handle is repr( 'CPointer' ) {

  sub curl_easy_init( --> Handle ) is native( LIB ) { * }
  sub curl_easy_cleanup( Handle )  is native( LIB ) { * }
  sub curl_easy_reset( Handle )    is native( LIB ) { * }

  sub curl_easy_escape(   Handle, Buf, int32              --> Pointer ) is native( LIB ) { * }
  sub curl_easy_unescape( Handle, Buf, int32, int32 is rw --> Pointer ) is native( LIB ) { * }

  sub curl_easy_setopt_str(  Handle, uint32, Str     --> uint32 ) is native( LIB ) is symbol( 'curl_easy_setopt' ) { * }
  sub curl_easy_setopt_ptr(  Handle, uint32, Pointer --> uint32 ) is native( LIB ) is symbol( 'curl_easy_setopt' ) { * }
  sub curl_easy_setopt_long( Handle, uint32, long    --> uint32 ) is native( LIB ) is symbol( 'curl_easy_setopt' ) { * }

  sub curl_easy_setopt_data-cb( Handle, uint32, &cb ( Pointer, uint32, uint32, Pointer --> uint32 ) --> uint32 )  is native( LIB ) is symbol('curl_easy_setopt') { * }

  sub curl_easy_perform( Handle --> uint32 ) is native( LIB ) { * }


  method new( --> Handle ) { curl_easy_init }

  method cleanup( ) { curl_easy_cleanup(self) }

  method reset( ) { curl_easy_reset(self) }


  method escape( Str $str, $encoding = 'utf-8' ) {

    my $buf = $str.encode( $encoding );
    my $ptr = curl_easy_escape( self, $buf, $buf.elems );
    my $esc = nativecast( Str, $ptr );

    curl_free( $ptr );

    return $esc;
  }

  method unescape( Str $str, $encoding = 'utf-8' ) {

    my int32 $outlength;

    my $buf = $str.encode( $encoding );

    my $ptr = curl_easy_unescape( self, $buf, $buf.elems, $outlength );
    my $arr = nativecast( CArray[ int8 ], $ptr );

    my $outstr = Buf.new( $arr[ 0 ..^ $outlength ] ).decode( $encoding );

    curl_free( $ptr );

    return $outstr;
  }

  method perform( ) { curl_easy_perform( self ) }

  multi method setopt( $option, Str $param ) {

    my $ret = curl_easy_setopt_str( self, $option, $param );

    die X::Pakku::Curl.new( code => $ret ) unless $ret == CURLE_OK;

  }

  multi method setopt( $option, Int $param ) {

    my $ret = curl_easy_setopt_long( self, $option, $param );

    die X::Pakku::Curl.new( code => $ret ) unless $ret == CURLE_OK;

  }

  multi method setopt( $option, &callback ) {

    my $ret = curl_easy_setopt_data-cb( self, $option, &callback );

    die X::Pakku::Curl.new( code => $ret ) unless $ret == CURLE_OK;

  }

  multi method setopt( $option, Pointer $ptr ) {

    my $ret = curl_easy_setopt_ptr( self, $option, $ptr );

    die X::Pakku::Curl.new(code => $ret) unless $ret == CURLE_OK;

  }


  multi method setopt( $option, Handle $ptr ) {

    my $ret = curl_easy_setopt_ptr( self, $option, $ptr);

    die X::Pakku::Curl.new(code => $ret) unless $ret == CURLE_OK;

  }

}

sub curl_global_init( long --> uint32 ) is native( LIB ) { * }

sub curl_global_cleanup( ) is native( LIB ) { * }

sub curl_free( Pointer $ptr ) is native( LIB ) { * }

class X::Pakku::Curl is Exception {

  has Int $.code;

  sub curl_easy_strerror( uint32 --> Str ) is native( LIB ) { * }

  method Int( ) { $!code }

  method message( ) { curl_easy_strerror( $!code ) }

}


my $curl;

class Pakku::Curl {

  has Blob       $.buf;
  has IO::Handle $!download-fh;

  has Handle  $.handle handles <escape unescape>;

  method new( ) {


    constant CURLOPT_URL            = 10002;
    constant CURLOPT_WRITEDATA      = 10001;
    constant CURLOPT_WRITEFUNCTION  = 20011;
    constant CURLOPT_SSL_OPTIONS    = 216;
    constant CURLSSLOPT_NATIVE_CA   = 16;
    constant CURL_GLOBAL_DEFAULT    = 3;

    curl_global_init( CURL_GLOBAL_DEFAULT );

    my $handle = Handle.new;

    $handle.setopt( CURLOPT_WRITEDATA,     $handle              );
    $handle.setopt( CURLOPT_WRITEFUNCTION, &writefunction       );
    $handle.setopt( CURLOPT_SSL_OPTIONS,   CURLSSLOPT_NATIVE_CA );

    $curl = self.bless( :$handle );

    return $curl;
  }


  method content( :$URL!, :$encoding = 'utf-8' --> Str ) {

    $!buf = Buf.new;

    $!handle.setopt( CURLOPT_URL, $URL );

    my $ret = $!handle.perform;

    die X::Pakku::Curl.new( code => $ret ) unless $ret == CURLE_OK;

    $!buf.decode: $encoding

  }

 
  method download ( :$URL!, :$download! ) {

    $!buf = Buf.new;

    $!handle.setopt( CURLOPT_URL, $URL );

    my $ret = $!handle.perform;

    die X::Pakku::Curl.new( code => $ret ) unless $ret == CURLE_OK;

    $!download-fh = open $download, :w, :bin;

    $!download-fh.write: $!buf;

    close $!download-fh;

    $!download-fh = Nil;

  }


  sub writefunction( Pointer $ptr, uint32 $size, uint32 $nmemb, Pointer $handleptr --> uint32 ) {

    $curl.buf ~= Blob.new( nativecast( CArray[ uint8 ], $ptr )[ ^ $size * $nmemb ] );

    return $size * $nmemb;
  }

  method cleanup {

    close( $!download-fh ) if $!download-fh;

    $!download-fh = Nil;

    .cleanup with $!handle;

    $!handle = Handle;
  }

  method reset( ) { $!handle.reset; $!buf = Nil, $!download-fh = Nil }

  submethod DESTROY { self.cleanup; curl_global_cleanup()}

}

