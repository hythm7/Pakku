unit class Build;

submethod BUILD ( ) {


  my $pakku-repo-path = $*HOME.add: '.pakku';

  my $dep-dir = $pakku-repo-path.add: 'dep';

  $dep-dir.mkdir;

  my @dep = (

    'File::Directory::Tree' => 'git://github.com/labster/p6-file-directory-tree.git',
    'File::Temp'            => 'git://github.com/perlpilot/p6-File-Temp.git',
    'JSON::Fast'            => 'git://github.com/timo/json_fast.git',
    'LibCurl'               => 'https://github.com/CurtTilmes/perl6-libcurl.git',
    'Hash::Merge::Augment'  => 'https://github.com/scriptkitties/p6-Hash-Merge.git',
    'Terminal::ANSIColor'   => 'git://github.com/tadzik/Terminal-ANSIColor.git',
    'Log::Async'            => 'git://github.com/bduggan/p6-log-async.git',
  );

  my $pakku-repo = CompUnit::Repository::Installation.new( prefix => $pakku-repo-path, next-repo => $*REPO );

  for @dep {

    my $dep-path = $dep-dir.add: .key;

    my $proc = run 'git', 'clone', .value, $dep-path, :out, :err;
    
    $proc.err.lines.Str.say;

    $pakku-repo.install: Distribution::Path.new: $dep-path;

  };

  use File::Directory::Tree;

  rmtree $dep-dir;

  True;
}
