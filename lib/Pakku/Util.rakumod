unit module Pakku::Util;


sub nuke-dir ( IO::Path:D $dir ) is export {

  return unless $dir.d;

  for $dir.dir {
    when :f { .unlink };
    nuke-dir .self when :d;
  }

  $dir.rmdir;
}


# Stolen from Hash::Merge:cpan:TYIL to fix #6
sub hashmerge ( %merge-into, %merge-source ) is export {

  for %merge-source.keys -> $key {
    if %merge-into{$key}:exists {
      given %merge-source{$key} {
        when Hash {
          hashmerge %merge-into{$key}, %merge-source{$key};
        }
        default { %merge-into{$key} = %merge-source{$key} }
      }
    }
    else {
      %merge-into{$key} = %merge-source{$key};
    }
  }

  %merge-into;
}


# adboted from Archive::Libarchive::Raw examples

sub extract( Str:D :$archive!, Str:D :$dest! ) is export {

  use NativeCall;
  use Archive::Libarchive::Raw;
  use Archive::Libarchive::Constants;

  my archive $a = archive_read_new;
  archive_read_support_format_all $a;
  archive_read_support_filter_gzip $a;
  archive_read_open_filename($a, $archive, 10240) == ARCHIVE_OK or die 'Unable to open archive';

  my archive $ext = archive_write_disk_new;

  my int64 $flags =
    ARCHIVE_EXTRACT_TIME   +|
    ARCHIVE_EXTRACT_PERM   +|
    ARCHIVE_EXTRACT_ACL    +|
    ARCHIVE_EXTRACT_UNLINK +|
    ARCHIVE_EXTRACT_FFLAGS;

  archive_write_disk_set_options $ext, $flags;
  archive_write_disk_set_standard_lookup $ext;

  my archive_entry $entry .= new;

  loop {
    given archive_read_next_header($a, $entry) {
      when ARCHIVE_EOF {
        last;
      }

      when $_ > ARCHIVE_OK {
        die;
      }
    }

    my $path = archive_entry_pathname( $entry );
    my $pathname = ~ $dest.IO.add( $path.IO.relative: $*SPEC.splitdir( $path ).head );

    archive_entry_set_pathname $entry, $pathname;

    my $res = archive_write_header($ext, $entry);

    if archive_entry_size($entry) >= 0 {
      $res = copy_data $a, $ext;
      if $res > ARCHIVE_OK {
        die archive_error_string($a);
      }
    }

    $res = archive_write_finish_entry $ext;

    if $res > ARCHIVE_OK {
      die;
    }
  }

  archive_read_close $a;
  archive_read_free($a);
  archive_write_close $ext;
  archive_write_free $ext;


  sub copy_data(archive $ar, archive $aw --> int64) {

    my int64 $res;
    my Pointer[void] $buff .= new;
    my int64 $size;
    my int64 $offset;

    loop {
      $res = archive_read_data_block $ar, $buff, $size, $offset;
      if $res == ARCHIVE_EOF {
        return ARCHIVE_OK;
      }
      if $res > ARCHIVE_OK {
        return $res;
      }

      $res = archive_write_data_block $aw, $buff, $size, $offset;

      if $res > ARCHIVE_OK {
        #say archive_error_string($aw);
        return $res;
      }
    }
  }
}

