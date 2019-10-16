unit class Build;

submethod BUILD ( ) {

  my $pakku-dir = $*HOME.add:     '.pakku';
  my $repo-dir  = $pakku-dir.add: '.repo';
  my $tmp-dir   = $pakku-dir.add: 'tmp';

  $repo-dir.mkdir;
  $tmp-dir.mkdir;

  my @dep = (

    'File::Directory::Tree'    => 'https://github.com/labster/p6-file-directory-tree.git',
    'File::Temp'               => 'https://github.com/perlpilot/p6-File-Temp.git',
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
  );

  my $pakku-repo = CompUnit::Repository::Installation.new( prefix => $repo-dir, next-repo => $*REPO );

  for @dep {

    my $dep-path = $tmp-dir.add: .key;

    my $proc = run 'git', 'clone', .value, $dep-path, :out, :err;

    $proc.out.lines.Str.say;
    $proc.err.lines.Str.say;

    $pakku-repo.install: :force, Distribution::Path.new: $dep-path;

  }

  use File::Directory::Tree;

  rmtree $tmp-dir;

  True;

}
