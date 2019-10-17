#!/usr/bin/env perl6

sub MAIN ( IO( ) :$dest = $*HOME.add: '.pakku' ) {

  my $pakku-src      = $?FILE.IO.parent(2);
  my $pakku-repo-dir = $dest.add: '.repo';

  my $tmp = $dest.add: 'tmp';

  $pakku-repo-dir.mkdir;
  $tmp.mkdir;


  my @dep = (

    'File::Directory::Tree'    => 'https://github.com/labster/p6-file-directory-tree.git',
    'File::Temp'               => 'https://github.com/perlpilot/p6-File-Temp.git',
    'Concurrent::File::Find'   => 'https://github.com/gfldex/perl6-concurrent-file-find.git',
    'Hash::Merge::Augment'     => 'https://github.com/scriptkitties/p6-Hash-Merge.git',
    'Terminal::ANSIColor'      => 'https://github.com/tadzik/Terminal-ANSIColor.git',
    'Log::Async'               => 'https://github.com/bduggan/p6-log-async.git',
    'JSON::Fast'               => 'https://github.com/timo/json_fast.git',
    'LibCurl'                  => 'https://github.com/CurtTilmes/perl6-libcurl.git',
    'Archive::Libarchive::Raw' => 'https://github.com/frithnanth/perl6-Archive-Libarchive-Raw.git',
    'NativeHelpers::Callback'  => 'https://github.com/CurtTilmes/perl6-nativehelpers-callback.git',
    'Number::Bytes::Human'     => 'https://github.com/dugword/Number-Bytes-Human.git',
    'BitEnum'                  => 'https://github.com/CurtTilmes/perl6-bitenum.git',
    'Libarchive'               => 'https://github.com/CurtTilmes/perl6-libarchive.git',
    'Cro::Core'                => 'https://github.com/croservices/cro-core.git',
    'System::Query'            => 'https://github.com/tony-o/p6-warthog.git',
    'Distribution::Builder::MakeFromJSON' => 'https://github.com/niner/Distribution-Builder-MakeFromJSON.git',
  );

  my $pakku-repo = CompUnit::Repository::Installation.new( prefix => $pakku-repo-dir, next-repo => $*REPO );

  for @dep {

    my $dep-dir = $tmp.add: .key;

    my $proc = run 'git', 'clone', .value, $dep-dir, :out, :err;

    $proc.out.lines.Str.say;
    $proc.err.lines.Str.say;

    $pakku-repo.install: :force, Distribution::Path.new: $dep-dir;

  }

   my $proc = run ~$*EXECUTABLE, "-I$pakku-repo,$pakku-src", $pakku-src.add( 'bin/pakku' ), 'add', $pakku-src, :out, :err;

  $proc.out.lines.Str.say;
  $proc.err.lines.Str.say;

 
  #use File::Directory::Tree;

  #rmtree $tmp;

  #build $pakku-src;
  #test  $pakku-src;

  #$pakku-repo.install: :force, Distribution::Path.new: $pakku-src;

}


sub build ( $pakku-src ) {

  say "Building Pakku...";

  my $build-file = $pakku-src.add: 'Build.rakumod';
  my $include    = "-I $pakku-src";
  my $execute    = "-e";

  my $build-cmd  = qq:to/CMD/;
  require "$build-file";
  ::( 'Build' ).new.build( "$pakku-src" );
  CMD

  my $proc = run ~$*EXECUTABLE, $include, $execute, $build-cmd, cwd => $pakku-src, :out, :err;

  $proc.out.lines.Str.say;
  $proc.err.lines.Str.say;

  die "Build failed for Pakku" if $proc.exitcode;
}


sub test ( $pakku-src ) {

  my $test-dir  = $pakku-src.add: 'tests';

  my @test = $test-dir.dir.grep( *.f );

  say "Testing...";

  my $lib-dir = $pakku-src.add( 'lib' );
  my $include = "-I $lib-dir";

  my @exitcode = @test.map( -> $test {

    my $exitcode;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $include, $test;

      whenever $proc.stdout.lines { say $^out }
      whenever $proc.stderr.lines { say $^err }
      whenever $proc.start( cwd => $pakku-src ) { $exitcode = .exitcode }

    }

    $exitcode;

  });

  die "Test failed for Pakku" if any @exitcode;

}
