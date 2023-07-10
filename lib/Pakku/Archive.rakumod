use NativeCall;

use Pakku::Native;

unit module Pakku::Archive;

BEGIN my $lib     = 'archive';
BEGIN my $version = v13;

constant LIB = (
  $*VM.platform-library-name( $lib.IO, :$version ).Str,
  $*VM.platform-library-name( $lib.IO            ).Str, 
).first( -> \lib { Pakku::Native.can-load: lib } );


constant ARCHIVE_OK  = 0;
constant ARCHIVE_EOF = 1;
constant EXT_FLAGS   = 0x0002 +| 0x0004 +| 0x0010 +| 0x0020 +| 0x0040;
 

class archive       is repr('CPointer') { * }
class archive_entry is repr('CPointer') { * }

sub archive_read_new(  --> archive       ) is native( LIB ) { * }
sub archive_entry_new( --> archive_entry ) is native( LIB ) { * }
sub archive_write_finish_entry( archive $archive --> int32 ) is native( LIB ) { * }


sub archive_read_free(  archive $archive --> int32 ) is native( LIB ) { * }
sub archive_read_close( archive $archive --> int32 ) is native( LIB ) { * }

sub archive_read_support_format_tar(  archive $archive --> int32 ) is native( LIB ) { * }
sub archive_read_support_filter_gzip( archive $archive --> int32 ) is native( LIB ) { * }

sub archive_read_open_memory( archive $archive, Buf $data, size_t $size --> int32 ) is native( LIB ) { * }
sub archive_read_data(archive $archive, Blob $buf, size_t $len --> size_t) is native(LIB) is export { * }

sub archive_read_next_header( archive $archive, archive_entry $entry is rw --> int32 ) is native( LIB ) { * }
sub archive_read_data_skip( archive $archive --> int32 ) is native( LIB ) { * }

sub archive_entry_clone( archive_entry --> archive_entry ) is native( LIB ) is export { * }

sub archive_entry_size(     archive_entry $archive_entry --> int64 ) is native( LIB ) { * }
sub archive_entry_pathname( archive_entry $archive_entry --> Str   ) is native( LIB ) { * }

sub archive_entry_free( archive_entry $archive_entry ) is native( LIB ) { * }

sub archive_entry_set_pathname( archive_entry $archive_entry, Str $filename ) is native( LIB ) { * }

sub archive_write_disk_new( --> archive ) is native( LIB ) { * }

sub archive_write_disk_set_options( archive $archive, int32 $flags --> int32 ) is native( LIB ) { * }
sub archive_write_disk_set_standard_lookup( archive $archive --> int32 ) is native( LIB ) { * }

sub archive_write_header( archive $archive, archive_entry $entry --> int32 ) is native( LIB ) { * }

sub archive_write_data(archive $archive, Buf $data, size_t $size --> size_t) is native(LIB) is export { * }

sub archive_write_close( archive $archive --> int32 ) is native( LIB ) { * }
sub archive_write_free(  archive $archive --> int32 ) is native( LIB ) { * }

sub archive_error_string( archive $archive --> Str ) is native( LIB ) { * }


my class Data { has size_t $.size; has Blob   $.buf; }

sub extract( IO::Path:D :$archive!, Str:D :$dest! --> Bool ) is export {

  my $buffer      = slurp $archive, :bin;
  my $buffer-size = $archive.IO.s;

  my archive $a = archive_read_new;

  archive_read_support_format_tar $a;
  archive_read_support_filter_gzip $a;
  archive_read_open_memory( $a, $buffer, $buffer-size ) == ARCHIVE_OK or die "Unable to open $archive";

  my %entries;

  my int64 $res;

  my archive_entry $entry .= new;

  while archive_read_next_header($a, $entry) == ARCHIVE_OK {

    my size_t $size = archive_entry_size( $entry );

    my $pathname = archive_entry_pathname( $entry );

    my $buf = buf8.allocate( $size ); 

    $res = archive_read_data $a, $buf, $size;

    my $data = Data.new: :$size :$buf;

    %entries{ archive_entry_pathname( $entry ) } =  ( archive_entry_clone( $entry ), $data );

  }

    my archive $e = archive_write_disk_new;

    archive_write_disk_set_options $e, EXT_FLAGS;
    archive_write_disk_set_standard_lookup $e;
  
  
    # get root dir from META file path
    my $root = %entries.keys.first( { .ends-with( any <META6.json META.info> ) and $*SPEC.splitdir( .IO.dirname ) == 1 } ).IO.dirname;
  
    for %entries.kv -> $pathname,  ( $entry, $data ) {
  
      archive_entry_set_pathname $entry, $dest.IO.add( $pathname.IO.relative( $root ) ).Str;
  
      my $res = archive_write_header($e, $entry);
  
      $res = archive_write_data $e, $data.buf, $data.size if $data.size;
  
      $res = archive_write_finish_entry $e;
  
      die if $res > ARCHIVE_OK;
    }
  
  archive_read_close  $a;
  archive_read_free   $a;
  archive_write_close $e;
  archive_write_free  $e;

  return True;
}

