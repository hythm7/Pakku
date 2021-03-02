#!/usr/bin/env raku

unit sub MAIN ( IO( ) :$dest = $*HOME.add( '.pakku' ).cleanup ); 

my $src      = $*PROGRAM.resolve.parent(2);

my $bin-dir  = $dest.add: 'bin';
my $dep-dir  = $dest.add: '.dep';
my $repo-dir = $dest.add: '.repo';

$bin-dir.mkdir;
$dep-dir.mkdir;
$repo-dir.mkdir;


my @dep = <

  File::Directory::Tree
  File::Temp
  File::Find
  File::Which
  Terminal::ANSIColor
  Log::Async
  JSON::Fast
  URL
  NativeLibs&auth=github:salortiz
  LibCurl
  Archive::Libarchive::Raw
  NativeHelpers::Callback
  Number::Bytes::Human
  BitEnum
  Libarchive
  URI::Encode
  Retry
  Pakku::Spec
  Pakku::Meta
  Pakku::RecMan::Client

>;


my $core = CompUnit::RepositoryRegistry.repository-for-name: 'core';
my $repo = CompUnit::Repository::Installation.new: prefix => $repo-dir;

CompUnit::RepositoryRegistry.register-name: 'pakku', $repo;
CompUnit::RepositoryRegistry.use-repository: $repo, current => $core;


for @dep -> $dep {

  my $dep-name =  $dep.split('&').head;

  my $meta-url = "http:/recman.pakku.org/recommend?name=$dep";

  my $meta = run 'curl', '-s', $meta-url, :out;

  my %meta = Rakudo::Internals::JSON.from-json($meta.out(:close).slurp);

  my $inst-dep = $repo.candidates( %meta<name> ).head;

  with $inst-dep {

    next if %meta<version>.Version ~~ $inst-dep.meta<ver>.Version; 

  }

  say "SPC: ｢$dep-name｣";

  my $src-path = $dep-dir.add: $dep-name;

  my $archive-path = "$src-path.tar.gz".IO;

  unlink $archive-path;

  my $curl = run 'curl', '-s', '-o', $archive-path, %meta<recman-src>;

  mkdir $src-path;

  my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';

  $repo.install: :force, Distribution::Path.new: $src-path;

}

my $cnf-src = $src.add:  'resources/pakku.cnf';
my $cnf-dst = $dest.add: 'pakku.cnf';

run 'cp', $cnf-src, $cnf-dst unless $cnf-dst.e;

my $bin-content = q:to/END/;
  #!/usr/bin/env raku

  use lib 'inst#' ~ $*PROGRAM.resolve.parent( 2 ) ~ '/.repo';

  use Pakku;

  Pakku.new.fun;

  END

my $bin = $bin-dir.add: 'pakku';

$bin.spurt: $bin-content;

$bin.IO.chmod(0o755);

run  $*EXECUTABLE, '-I', $src, $bin, 'verbose debug', 'add', 'force', 'to', $repo-dir,  $src;

say "Pakku installed to: ｢$bin｣";
