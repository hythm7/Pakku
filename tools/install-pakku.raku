#!/usr/bin/env raku

unit sub MAIN ( IO( ) :repo(:$dest) = $*HOME.add( '.pakku' ).cleanup ); 

my $src      = $*PROGRAM.resolve.parent(2);

my $dep-dir  = $dest.add: '.dep';

$dep-dir.mkdir;

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


my $repo = CompUnit::RepositoryRegistry.repository-for-spec: "inst#$dest";
CompUnit::RepositoryRegistry.register-name: 'pakku', $repo;
CompUnit::RepositoryRegistry.use-repository: $repo;


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

my $bin     = $src.add: 'bin/pakku';
my $include = "$src,{ $repo.path-spec }";

run $*EXECUTABLE, '-I', $include, $bin, 'verbose debug', 'add', 'force', 'to', $repo,  $src;

my $src-cnf = $src.add:  'resources/pakku.cnf';
my $dst-cnf = $dest.add: 'pakku.cnf';

run 'cp', $src-cnf, $dst-cnf unless $dst-cnf.e;

my $wrapper = $repo.prefix.add: 'bin/pakku';

my $wrapper-content = q:to:!s/END/;
  #!/usr/bin/env #raku#

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec: 'inst#' ~ $*PROGRAM.resolve.parent( 2 );

  CompUnit::RepositoryRegistry.register-name: 'pakku', $repo;

  CompUnit::RepositoryRegistry.use-repository: $repo;

  unit sub MAIN(:$name, :$auth, :$ver, *@, *%);

  CompUnit::RepositoryRegistry.run-script( 'pakku', :$name, :$auth, :$ver );

  END

for '', '-m', '-j', '-js' -> $backend {

  my $wrapper = $repo.prefix.add: 'bin/pakku' ~ $backend;

  $wrapper.spurt: $wrapper-content.subst: '#raku#', 'perl6' ~ $backend;

  $wrapper.IO.chmod(0o755);;

}
