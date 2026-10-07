#!/usr/bin/env raku
# Hostile and odd archives for t/archive.rakutest, written as plain ustar so
# no compressor is needed. Dev-time tool; the generated .tar files are committed.
my $here = $*PROGRAM.parent;

sub header ( Str $name, Int $size, Str :$type = '0', Str :$link = '', Int :$mode = 0o644 --> Buf ) {
  my $h = Buf.new( 0 xx 512 );
  sub put ( Int $off, Str $s ) { my $b = $s.encode; $h.subbuf-rw( $off, $b.bytes ) = $b }
  put   0, $name.substr( 0, 100 );
  put 100, sprintf( '%07o', $mode );
  put 108, '0000000';
  put 116, '0000000';
  put 124, sprintf( '%011o', $size );
  put 136, sprintf( '%011o', 0 );
  put 148, ' ' x 8;
  put 156, $type;
  put 157, $link.substr( 0, 100 );
  put 257, "ustar\0";
  put 263, '00';
  put 148, sprintf( '%06o', [+] $h.list ) ~ "\0 ";
  $h;
}

sub entry ( Str $name, Blob $data = Blob.new, *%o --> Buf ) {
  my $b = header( $name, $data.bytes, |%o );
  $b.append( $data );
  $b.append( 0 xx ( 512 - $data.bytes % 512 ) ) if $data.bytes % 512;
  $b;
}

sub tar ( Str $file, *@entries ) {
  my $b = Buf.new;
  $b.append( $_ ) for @entries;
  $b.append( 0 xx 1024 );
  $here.add( $file ).spurt: $b;
  say $file;
}

my $meta = '{"name":"Evil","version":"0.0.1","auth":"zef:evil","provides":{}}'.encode;

tar 'dotdot.tar',   entry( 'dist/META6.json', $meta ), entry( 'dist/../../escaped.txt', 'escaped'.encode );
tar 'absolute.tar', entry( 'dist/META6.json', $meta ), entry( '/tmp/pakku-evil-escaped.txt', 'escaped'.encode );
tar 'symlink.tar',  entry( 'dist/META6.json', $meta ), entry( 'dist/evil', type => '2', link => '/tmp' ), entry( 'dist/evil/through.txt', 'x'.encode );
tar 'hardlink.tar', entry( 'dist/META6.json', $meta ), entry( 'dist/hl', type => '1', link => '/etc/hostname' );
tar 'nometa.tar',   entry( 'foo/bar.txt', 'hi'.encode );
tar 'twometa.tar',  entry( 'dist/META6.json', $meta ), entry( 'dist/lib/X.rakumod', 'unit module X;'.encode ), entry( 'other/META6.json', '{}'.encode );
tar 'suid.tar',     entry( 'dist/META6.json', $meta ), entry( 'dist/bin/tool', "#!/bin/sh\n".encode, mode => 0o4755 );

# sizes that lie: 64 MiB declared with 10 bytes present, and 7 GiB declared
$here.add( 'shortread.tar' ).spurt: entry( 'dist/META6.json', $meta ) ~ header( 'dist/big.bin',  64 * 1024 ** 2 ) ~ '0123456789'.encode;
$here.add( 'hugesize.tar'  ).spurt: entry( 'dist/META6.json', $meta ) ~ header( 'dist/huge.bin', 7  * 1024 ** 3 ) ~ '0123456789'.encode;

# a good archive, and the same stream cut in half
my $good = Buf.new;
$good.append( entry( 'dist/META6.json', $meta ) );
$good.append( entry( "dist/lib/M$_.rakumod", ( "unit module M$_;\n" x 50 ).encode ) ) for ^20;
$good.append( 0 xx 1024 );
$here.add( 'good.tar'      ).spurt: $good;
$here.add( 'truncated.tar' ).spurt: $good.subbuf( 0, $good.bytes div 2 + 100 );   # cut inside a data block
run 'gzip', '-kf', $here.add( 'good.tar' );                                            # good.tar.gz, then cut the gzip stream
my $gz = $here.add( 'good.tar.gz' ).slurp( :bin );
$here.add( 'truncated.tar.gz' ).spurt: $gz.subbuf( 0, $gz.bytes div 2 );
say 'shortread.tar hugesize.tar good.tar good.tar.gz truncated.tar truncated.tar.gz';
