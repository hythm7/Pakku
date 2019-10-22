#!/usr/bin/env perl6

sub MAIN ( IO( ) :$dest = $*HOME.add: '.pakku' ) {

  my $src      = $?FILE.IO.parent(2);

  my $bin-dir  = $dest.add: 'bin';
  my $dep-dir  = $dest.add: '.dep';
  my $repo-dir = $dest.add: '.repo';

  $bin-dir.mkdir;
  $dep-dir.mkdir;
  $repo-dir.mkdir;


  my @dep = (

    'File::Directory::Tree'
      => 'https://github.com/labster/p6-file-directory-tree.git',
    'File::Temp'
      => 'https://github.com/perlpilot/p6-File-Temp.git',
    'Concurrent::File::Find'
      => 'https://github.com/gfldex/perl6-concurrent-file-find.git',
    'Hash::Merge::Augment'
      => 'https://github.com/scriptkitties/p6-Hash-Merge.git',
    'Terminal::ANSIColor'
      => 'https://github.com/tadzik/Terminal-ANSIColor.git',
    'Log::Async'
      => 'https://github.com/bduggan/p6-log-async.git',
    'JSON::Fast'
      => 'https://github.com/timo/json_fast.git',
    'LibCurl'
      => 'https://github.com/CurtTilmes/perl6-libcurl.git',
    'Archive::Libarchive::Raw'
      => 'https://github.com/frithnanth/perl6-Archive-Libarchive-Raw.git',
    'NativeHelpers::Callback'
      => 'https://github.com/CurtTilmes/perl6-nativehelpers-callback.git',
    'Number::Bytes::Human'
      => 'https://github.com/dugword/Number-Bytes-Human.git',
    'BitEnum'
      => 'https://github.com/CurtTilmes/perl6-bitenum.git',
    'Libarchive'
      => 'https://github.com/CurtTilmes/perl6-libarchive.git',
    'Cro::Core'
      => 'https://github.com/croservices/cro-core.git',
    'System::Query'
      => 'https://github.com/tony-o/p6-warthog.git',
    'Distribution::Builder::MakeFromJSON'
      => 'https://github.com/niner/Distribution-Builder-MakeFromJSON.git',
  );


  my $pakku-repo = CompUnit::Repository::Installation.new( prefix => $repo-dir );

  CompUnit::RepositoryRegistry.use-repository: $pakku-repo;

  for @dep {

     my $src-path = $dep-dir.add: .key;
     my $src-url  = .value;

     say "Installing Pakku dependency [{$src-path.basename}]";

     # TODO: Replace git with curl
     my $proc = run 'git', 'clone', $src-url, $src-path, :out, :err unless $src-path.d;

     $proc.out.slurp( :close ).say with $proc;
     $proc.err.slurp( :close ).say with $proc;

     $pakku-repo.install: :force, Distribution::Path.new: $src-path;

  }


  say "Installing Pakku...";

  my $pakku-bin = $bin-dir.add: 'pakku';

  my $pakku-bin-content = qq:to/END/;
  #!/usr/bin/env perl6

  # use Pakku's dependencies repo
  use lib '{$pakku-repo.path-spec}';

  use Pakku;

  Pakku.new;

  END

  $pakku-bin.spurt: $pakku-bin-content;
  run 'chmod', '+x', $pakku-bin;

  %*ENV<PERL6LIB>  = "$src, {$pakku-repo.path-spec}";

  run $pakku-bin, 'verbose 1', 'build', $src;
  run $pakku-bin, 'verbose 1', 'test',  $src;


  my $src-cnf = $src.add:  'resources/pakku.cnf';
  my $dst-cnf = $dest.add: 'pakku.cnf';

  run 'cp', $src-cnf, $dst-cnf unless $dst-cnf.e;


  $pakku-repo.install: :force, Distribution::Path.new: $src;

  say "Pakku installed to $pakku-bin";

}
