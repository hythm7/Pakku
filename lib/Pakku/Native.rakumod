use NativeCall;

### borrowed from NativeLibs:ver<0.0.9>:auth<github:salortiz>
### to avoid a dependency

use X::Pakku;

unit class Pakku::Native;

class DLLib is repr('CPointer') { }

constant IS-WIN = Rakudo::Internals.IS-WIN();

my  \dyncall = $*VM.config<nativecall_backend> eq 'dyncall';

constant k32 = 'kernel32';


sub dlopen(        Str, uint32 --> DLLib ) is native        { * }
sub dlLoadLibrary( Str         --> DLLib ) is native        { * }
sub LoadLibraryA(  Str         --> DLLib ) is native( k32 ) { * }

method !dlLoadLibrary( Str $libname --> DLLib ) {

	IS-WIN ?? LoadLibraryA( $libname ) !!  dyncall ?? dlLoadLibrary( $libname ) !!  dlopen( $libname, 0x102 );

}

method can-load( ::?CLASS:U: Str:D( ) $libname --> Bool:D ) {

	my \lib = self!dlLoadLibrary( $libname );

  return False unless lib;

  IS-WIN ?? FreeLibrary( lib ) !! dyncall ?? dlFreeLibrary( lib ) !! dlclose( lib );
  
  return True;
}

sub dlFreeLibrary( DLLib           ) is native        { * }
sub dlclose(       DLLib           ) is native        { * }
sub FreeLibrary(   DLLib --> int32 ) is native( k32 ) { * }
