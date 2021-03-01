#!/usr/bin/env raku

use lib $*PROGRAM.IO.parent(2);

use Pakku::Log;

unit sub MAIN (
  IO( ) :$dest    = $*HOME.add( '.pakku' ).cleanup,
        :$verbose = 3,
        :$pretty  = True 
);

Pakku::Log.new: :$verbose :$pretty;

my $src      = $*PROGRAM.IO.parent(2);

my $bin-dir  = $dest.add: 'bin';
my $dep-dir  = $dest.add: '.dep';
my $repo-dir = $dest.add: '.repo';

🤓 "SRC: ｢$src｣";
🤓 "DST: ｢$dest｣";

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


my $pakku-repo = CompUnit::Repository::Installation.new: prefix => $repo-dir;

CompUnit::RepositoryRegistry.register-name: 'pakku', $pakku-repo;
CompUnit::RepositoryRegistry.use-repository: $pakku-repo;


for @dep -> $dep {

  my $dep-name =  $dep.split('&').head;

  🐞 "SPC: ｢$dep-name｣";

  my $meta-url = "http:/recman.pakku.org/recommend?name=$dep";

🤓 "FTC: ｢$meta-url｣";

  my $meta = run 'curl', '-s', $meta-url, :out;

  my %meta = Rakudo::Internals::JSON.from-json($meta.out(:close).slurp);

  my $inst-dep = $pakku-repo.candidates( %meta<name> ).head;

  with $inst-dep {

    next if %meta<version>.Version ~~ $inst-dep.meta<ver>.Version; 

  }

  my $long-name = "%meta<name>:ver<%meta<version>>:auth<%meta<auth>>:api<%meta<api>>";

  my $src-path = $dep-dir.add: $dep-name;

  my $archive-path = "$src-path.tar.gz".IO;

  unlink $archive-path;

  🤓 "FTC: ｢$archive-path｣";

  my $curl = run 'curl', '-s', '-o', $archive-path, %meta<recman-src>;

  mkdir $src-path;

  my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';

  $pakku-repo.install: :force, Distribution::Path.new: $src-path;

  🦋 "ADD: ｢$long-name｣";

}

my $pakku-bin = $bin-dir.add: 'pakku';

my $pakku-bin-content = qq:to:!s/END/;
  #!/usr/bin/env raku

  use lib 'inst#' ~ $*PROGRAM.resolve.parent( 2 ) ~ '/.repo';

  use Pakku;

  Pakku.new.fun;

  END

$pakku-bin.spurt: $pakku-bin-content;
run 'chmod', '+x', $pakku-bin;

%*ENV<RAKULIB>  = "$src, { $pakku-repo.path-spec }";

my $src-cnf = $src.add:  'resources/pakku.cnf';
my $dst-cnf = $dest.add: 'pakku.cnf';

run 'cp', $src-cnf, $dst-cnf unless $dst-cnf.e;

quietly run $pakku-bin, 'verbose debug', 'add', 'force', 'to', $repo-dir,  $src;

🦋 "ADD: ｢$pakku-bin｣";
