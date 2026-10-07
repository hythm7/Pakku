use NativeCall;

use X::Pakku;
use Pakku::Log;
use Pakku::Native;

# Extract a distribution archive (tar.gz, but anything libarchive reads) into
# a directory, safely: entries are validated before anything touches the disk
# and data is streamed block by block, never buffered whole.
unit module Pakku::Archive;

constant ARCHIVE_EOF    =   1;
constant ARCHIVE_OK     =   0;
constant ARCHIVE_WARN   = -20;

# TIME | SECURE_NODOTDOT. Absolute paths, '..' and link entries are rejected
# by validate() below, so SECURE_NOABSOLUTEPATHS (our targets are absolute)
# and SECURE_SYMLINKS (a symlinked $HOME is legitimate) are not needed.
constant EXT_FLAGS = 0x0004 +| 0x0200;

constant AE_IFMT  = 0o170000;
constant AE_IFREG = 0o100000;
constant AE_IFDIR = 0o040000;

constant MAX-BYTES = 2 * 1024 ** 3;   # refuse to extract more than 2 GiB from one dist

class archive       is repr('CPointer') { }
class archive_entry is repr('CPointer') { }

# resolved on first use, so Pakku loads (help, list, config ...) without libarchive
my sub lib ( --> Str:D ) {

  state $lib = (
    $*VM.platform-library-name( 'archive'.IO, version =>  v13 ).Str,
    $*VM.platform-library-name( 'archive'.IO                  ).Str,
    $*VM.platform-library-name( 'archiveint'.IO               ).Str,
  ).first( -> $lib { Pakku::Native.can-load: $lib } );

  $lib // die X::Pakku::Native.new: msg => 'libarchive', comment => 'not found!';

}

sub archive_read_new                    ( --> archive                             ) is native( &lib ) { * }
sub archive_read_support_format_all     ( archive --> int32                       ) is native( &lib ) { * }
sub archive_read_support_filter_all     ( archive --> int32                       ) is native( &lib ) { * }
sub archive_read_open_filename          ( archive, Str, size_t --> int32          ) is native( &lib ) { * }
sub archive_read_next_header            ( archive, archive_entry is rw --> int32  ) is native( &lib ) { * }
sub archive_read_data_block             ( archive, Pointer is rw, size_t is rw, int64 is rw --> int32 ) is native( &lib ) { * }
sub archive_read_data_skip              ( archive --> int32                       ) is native( &lib ) { * }
sub archive_read_close                  ( archive --> int32                       ) is native( &lib ) { * }
sub archive_read_free                   ( archive --> int32                       ) is native( &lib ) { * }

sub archive_write_disk_new              ( --> archive                             ) is native( &lib ) { * }
sub archive_write_disk_set_options      ( archive, int32 --> int32                ) is native( &lib ) { * }
sub archive_write_disk_set_standard_lookup ( archive --> int32                    ) is native( &lib ) { * }
sub archive_write_header                ( archive, archive_entry --> int32        ) is native( &lib ) { * }
sub archive_write_data_block            ( archive, Pointer, size_t, int64 --> ssize_t ) is native( &lib ) { * }
sub archive_write_finish_entry          ( archive --> int32                       ) is native( &lib ) { * }
sub archive_write_close                 ( archive --> int32                       ) is native( &lib ) { * }
sub archive_write_free                  ( archive --> int32                       ) is native( &lib ) { * }

sub archive_error_string                ( archive --> Str                         ) is native( &lib ) { * }

sub archive_entry_pathname              ( archive_entry --> Str                   ) is native( &lib ) { * }
sub archive_entry_set_pathname          ( archive_entry, Str                      ) is native( &lib ) { * }
sub archive_entry_filetype              ( archive_entry --> uint32                ) is native( &lib ) { * }
sub archive_entry_hardlink              ( archive_entry --> Str                   ) is native( &lib ) { * }
sub archive_entry_size                  ( archive_entry --> int64                 ) is native( &lib ) { * }

my sub open-archive ( IO::Path:D $archive --> archive ) {

  my $a = archive_read_new;

  archive_read_support_format_all $a;
  archive_read_support_filter_all $a;

  if archive_read_open_filename( $a, ~$archive, 65536 ) != ARCHIVE_OK {

    my $error = archive_error_string( $a );

    archive_read_free $a;

    die X::Pakku::Archive.new: msg => ~$archive, comment => $error // 'can not open!';

  }

  $a;

}

# libarchive returns negative codes on trouble: WARN is logged, worse is fatal
my sub check ( archive $a, Int $rc, Str $what, IO::Path $archive --> Nil ) {

  return if $rc >= ARCHIVE_OK;

  my $error = archive_error_string( $a ) // "error $rc";

  if $rc == ARCHIVE_WARN {

    log '🐞', header => 'ARC', msg => $what, comment => $error;

    return;

  }

  die X::Pakku::Archive.new: msg => ~$archive, comment => "$what: $error";

}

my sub components ( Str:D $path ) { $path.split( / <[ / \\ ]> / ).grep( * ne '' ).grep( * ne '.' ) }

# pass 1: every header, validated, nothing written
my sub entries ( IO::Path:D $archive ) {

  my $a = open-archive $archive;

  LEAVE { if $a { archive_read_close $a; archive_read_free $a } }

  my @entry;

  loop {

    my archive_entry $entry .= new;

    my $rc = archive_read_next_header( $a, $entry );

    last if $rc == ARCHIVE_EOF;

    check $a, $rc, 'read header', $archive;

    my $path = archive_entry_pathname( $entry ) // '';
    my $type = archive_entry_filetype( $entry ) +& AE_IFMT;

    die X::Pakku::Archive.new: msg => ~$archive, comment => "$path: absolute path!"
      if $path.starts-with( '/' ) or $path.starts-with( '\\' ) or $path ~~ / ^ <alpha> ':' /;

    die X::Pakku::Archive.new: msg => ~$archive, comment => "$path: '..' in path!"
      if components( $path ).first( '..' );

    die X::Pakku::Archive.new: msg => ~$archive, comment => "$path: link or special entry!"
      if $type != AE_IFREG | AE_IFDIR or archive_entry_hardlink( $entry );

    @entry.push: %( :$path, :$type, size => archive_entry_size( $entry ) );

    check $a, archive_read_data_skip( $a ), "$path: skip data", $archive;

  }

  @entry;

}

# the root is the directory holding the shallowest META6.json / META.info
my sub root-of ( @entry, IO::Path:D $archive ) {

  my @meta = @entry.grep( { .<type> == AE_IFREG and components( .<path> ).tail ~~ 'META6.json' | 'META.info' } )
                   .map(  { components( .<path> ).head( *-1 ).List } );

  die X::Pakku::Archive.new: msg => ~$archive, comment => 'no META6.json!' unless @meta;

  my $depth = @meta.map( *.elems ).min;

  my @root  = @meta.grep( *.elems == $depth ).unique( :with(&[eqv]) );

  die X::Pakku::Archive.new: msg => ~$archive, comment => "more than one dist root: { @root.map( *.join( '/' ) ).join( ', ' ) }" if @root > 1;

  @root.head;

}

sub extract ( IO::Path:D :$archive!, IO::Path:D :$dst! --> Bool:D ) is export {

  my @entry = entries $archive;
  my @root  = root-of( @entry, $archive ).flat;

  # path inside the archive => path relative to the dist root ('' for the root itself)
  my %relative;

  for @entry -> %e {

    my @c = components %e<path>;

    die X::Pakku::Archive.new: msg => ~$archive, comment => "{ %e<path> }: outside the dist root { @root.join( '/' ) }!"
      unless @c.head( +@root ).List eqv @root.List;

    %relative{ %e<path> } = @c[ +@root .. * ].join( '/' );

  }

  $dst.mkdir;

  # pass 2: stream the data to disk
  my $a = open-archive $archive;
  my $e = archive_write_disk_new;

  archive_write_disk_set_options $e, EXT_FLAGS;
  archive_write_disk_set_standard_lookup $e;

  LEAVE {
    if $e { archive_write_close $e; archive_write_free $e }
    if $a { archive_read_close  $a; archive_read_free  $a }
  }

  my $total = 0;

  loop {

    my archive_entry $entry .= new;

    my $rc = archive_read_next_header( $a, $entry );

    last if $rc == ARCHIVE_EOF;

    check $a, $rc, 'read header', $archive;

    my $path     = archive_entry_pathname( $entry );
    my $relative = %relative{ $path } // '';

    unless $relative.chars {

      check $a, archive_read_data_skip( $a ), "$path: skip data", $archive;

      next;

    }

    archive_entry_set_pathname $entry, ~$dst.add( $relative );

    check $e, archive_write_header( $e, $entry ), "$path: write header", $archive;

    if ( archive_entry_filetype( $entry ) +& AE_IFMT ) == AE_IFREG {

      loop {

        my Pointer $buff  .= new;
        my size_t  $size   = 0;
        my int64   $offset = 0;

        my $r = archive_read_data_block( $a, $buff, $size, $offset );

        last if $r == ARCHIVE_EOF;

        check $a, $r, "$path: read data", $archive;

        $total += $size;

        die X::Pakku::Archive.new: msg => ~$archive, comment => "more than { MAX-BYTES div 1024 ** 3 } GiB, refusing!" if $total > MAX-BYTES;

        my $w = archive_write_data_block( $e, $buff, $size, $offset );

        die X::Pakku::Archive.new: msg => ~$archive, comment => "$path: write data: " ~ ( archive_error_string( $e ) // "error $w" ) if $w < ARCHIVE_OK;

      }

    }

    check $e, archive_write_finish_entry( $e ), "$path: finish entry", $archive;

  }

  True;

}
