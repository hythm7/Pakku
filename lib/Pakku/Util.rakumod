use Pakku::Log;

unit module Pakku::Util;

# Retry an action with exponential back-off; rethrows the last error.
sub retry ( &action, Int:D :$max is copy = 4, Real:D :$delay is copy = 0.2 ) is export {

  loop {

    my $result = quietly try action();

    return $result unless $!;

    $!.rethrow if $max == 0;

    sleep $delay;

    log '🐞', header => 'TRY', msg => ~$!, :comment<retrying!>;

    $delay *= 2;
    $max   -= 1;

  }

}

# Copy a directory tree. Symlinks are never followed (a dist could point one at
# the user's home); they are skipped with a debug line.
sub copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst! --> Nil ) is export {

  for $src.dir -> $path {

    my $destination = $dst.add( $path.basename );

    if $path.l {

      log '🐛', header => 'CPY', msg => ~$path, comment => 'symlink skipped!';

    } elsif $path.d {

      $destination.mkdir;

      copy-dir src => $path, dst => $destination;

    } else {

      $destination.parent.mkdir;

      $path.copy: $destination;

    }
  }

}

# Remove a directory tree without descending into symlinked directories.
sub remove-dir ( IO::Path:D $io --> Nil ) is export {

  for $io.dir { ( .l or not .d ) ?? .unlink !! remove-dir( $_ ) }

  $io.rmdir;

}

sub sha1 ( Str:D $what --> Str:D ) is export { use nqp; nqp::sha1( $what ) }

# Is an executable called $name on PATH? Absolute PATH entries only, and the
# file must be executable (.exe/.bat/.cmd via PATHEXT on Windows).
sub find-bin ( Str:D $name --> Bool:D ) is export {

  my @ext = $*DISTRO.is-win ?? ( '', |( %*ENV<PATHEXT> // '.COM;.EXE;.BAT;.CMD' ).split( ';' ) ) !! ( '', );

  so $*SPEC.path.grep( *.IO.is-absolute ).first( -> $dir {

    defined @ext.first( -> $ext { my $file = $dir.IO.add( $name ~ $ext ); $file.f and ( $*DISTRO.is-win or $file.x ) } )

  } );

}

# Run &code while holding an advisory lock on $path (blocks until free).
sub lock-file ( IO::Path:D $path, &code, Bool :$shared = False ) is export {

  $path.parent.mkdir;

  my $fh = $path.open( :rw, :create );

  LEAVE $fh.close;

  $fh.lock: :$shared;

  code();

}

# The META file of a dist directory (S22 allows four names).
sub meta-file ( IO::Path:D $dir --> IO::Path ) is export {

  <META6.json META6.info META.json META.info>.map( { $dir.add: $_ } ).first( *.f );

}

# A Version from META data: a leading 'v' is tolerated, absent means 0 (as Rakudo's repos do).
sub version ( $v --> Version:D ) is export {

  Version.new( ( $v // 0 ).Str.subst( / ^ 'v' <?before \d> /, '' ) );

}

# a URL fit for a log line: https://user:secret@host/ -> https://***@host/
sub redact ( Str:D $url --> Str:D ) is export { $url.subst( / ^ ( \w+ '://' ) <-[/@]>+ '@' /, { $0 ~ '***@' } ) }
