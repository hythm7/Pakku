#!/usr/bin/env raku

sub MAIN ( IO( ) :$dest = $*HOME.add( '.pakku' ).cleanup ) {

  my $src      = $?FILE.IO.parent(2);

  my $bin-dir  = $dest.add: 'bin';
  my $dep-dir  = $dest.add: '.dep';
  my $repo-dir = $dest.add: '.repo';

  $bin-dir.mkdir;
  $dep-dir.mkdir;
  $repo-dir.mkdir;


  my @dep = (

    'File::Directory::Tree'
      => 'http://recman.pakku.org/archive/48b53d7d6b28fdae6b740dccaa8b67a86aaeff3aede42e62fd79a69dbe0c5482',
    'File::Temp'
      => 'http://recman.pakku.org/archive/4ff8672a8ff88b7b4a2a6201ed1eaedf9cba24cbe558510f566627083c7d57ca',
    'File::Find'
      => 'http://recman.pakku.org/archive/ee4bc10d5dc715b255bf9cda064ecbbd6f7e3328a1889fccd2bf0e0f6e5a5754',
    'Terminal::ANSIColor'
      => 'http://recman.pakku.org/archive/29d76ff4031311dda696c8d4911082d96ad78f85b51ad22426fee0fcb3255b84',
    'Log::Async'
      => 'http://recman.pakku.org/archive/62afbe0af32d4c174165e6ed5da6e33493619493b322ede933e6742b46003dc6',
    'JSON::Fast'
      => 'http://recman.pakku.org/archive/02191b34b0aa722abb3ad6d152b8d7586e7340c648e0f730c1f4cd1343c9c7cd',
    'URL'
      => 'http://recman.pakku.org/archive/1e53bfeefe5db9cd764b58bb9fe18af65bc59da88ca1dbd8f64093f6b5596df4',
    'NativeLibs'
      => 'http://recman.pakku.org/archive/ef5f740e3789379ca950254b78f84eb5fdb13c0159095457f8b2148cd852a957',
    'LibCurl'
      => 'http://recman.pakku.org/archive/c821f1d3878ae13feda854840490888aa00fef46cd786b699b9a29f6d71b4ae7',
    'Archive::Libarchive::Raw'
      => 'http://recman.pakku.org/archive/fbcf74cca144adadce6f721e53a6f646ddd44ac0cae4f7537d693321e72f402a',
    'NativeHelpers::Callback'
      => 'http://recman.pakku.org/archive/8311eb649af4fbf4828f7a1de00b17729918fea38f521e1d7a95bf7643f65675',
    'Number::Bytes::Human'
      => 'http://recman.pakku.org/archive/d54571995ddb38a6c80c1fb49018ca130c4b1dcec763b5e50c27631463ac8bcb',
    'BitEnum'
      => 'http://recman.pakku.org/archive/bd937bc029fc6fa20888e302fe25b726936ab30875b3a6656036f4d54606483a',
    'Libarchive'
      => 'http://recman.pakku.org/archive/c7b2052a1665180806fb431c960ca60e7abda4b00d2bed1c94b1476334b27f05',
    'Retry'
      => 'http://recman.pakku.org/archive/7f72c599cbdbaa275ad830e5aa59c32297777b372a923a88bcfdb68b146ed7de',
    'Pakku::Spec'
      => 'http://recman.pakku.org/archive/115c90d169c46cfa6f57afdb7345456f2ae09e8e8fef1dcdd90786a8a50dd889',
    'Pakku::Meta'
      => 'http://recman.pakku.org/archive/0eebddc662eccdcbebdcdc8690b63355008673e60fbf055bafb1f78b341da3fc',
    'Pakku::RecMan::Client'
      => 'http://recman.pakku.org/archive/638f1e3209abeba4ca95f85580af3e234deafdc3568f17cc718a560e93aaf769',
  );


  my $pakku-repo = CompUnit::Repository::Installation.new( prefix => $repo-dir, name => 'pakku' );

  CompUnit::RepositoryRegistry.register-name: 'pakku', $pakku-repo;
  CompUnit::RepositoryRegistry.use-repository: $pakku-repo;
 
  for @dep {

     my $src-path = $dep-dir.add: .key;
     my $src-url  = .value;

     say "Installing Pakku dependency [{.key}]";

     my $archive-path = "$src-path.tar.gz".IO;

     my $curl = run 'curl', '-s', '-o', $archive-path, $src-url, unless $archive-path.f;

     mkdir $src-path;

     my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';

     $pakku-repo.install: :force, Distribution::Path.new: $src-path;

  }


  say "Installing Pakku...";

  my $pakku-bin = $bin-dir.add: 'pakku';

  my $pakku-bin-content = qq:to/END/;
  #!/usr/bin/env raku

  # use Pakku's dependencies repo
  use lib '{ $pakku-repo.path-spec }';

  use Pakku;

  Pakku.new;

  END

  $pakku-bin.spurt: $pakku-bin-content;
  run 'chmod', '+x', $pakku-bin;

  %*ENV<RAKULIB>  = "$src, { $pakku-repo.path-spec }";

  my $src-cnf = $src.add:  'resources/pakku.cnf';
  my $dst-cnf = $dest.add: 'pakku.cnf';

  run 'cp', $src-cnf, $dst-cnf unless $dst-cnf.e;

  run $pakku-bin, 'verbose 1', 'add', 'force', 'to', $repo-dir,  $src;

  say "Pakku installed to ｢$pakku-bin｣";

}
