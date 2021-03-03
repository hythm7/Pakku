#!/usr/bin/env raku

unit sub MAIN (

  IO( )  :$dest    = $*HOME.add( '.pakku' ).cleanup,
  Int:D  :$verbose = 3,
  Bool:D :$pretty  = True,

); 

BEGIN my $dep-dir = $*TMPDIR.add( '.pakku-dep' ).mkdir;

sub log-dep ( ) {

  my @dep = <Terminal::ANSIColor Log::Async>;

  for @dep -> $dep {

    my $meta-url = "http:/recman.pakku.org/recommend?name=$dep";

    my $meta = run 'curl', '-s', $meta-url, :out;

    my %meta = Rakudo::Internals::JSON.from-json($meta.out(:close).slurp);

    my $src-path = $dep-dir.add: $dep;

    my $archive-path = "$src-path.tar.gz".IO;

    my $curl = run 'curl', '-s', '-o', $archive-path, %meta<recman-src>;

    mkdir $src-path;

    my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';

  }

  @dep.map( -> $dep { $dep-dir.add: $dep } );
}

BEGIN my ( $terminal-ansicolor, $log-async ) = log-dep( );

use lib $*PROGRAM.resolve.parent( 2 );
use lib $terminal-ansicolor;
use lib $log-async;

use Pakku::Log;

Pakku::Log.new: :$verbose :$pretty;

my $src      = $*PROGRAM.resolve.parent(2);

🦋 "PRC: ｢🦋｣";
🤓 "SRC: ｢$src｣";
🤓 "DST: ｢$dest｣";

my $bin-dir  = $dest.add( 'bin'   ).mkdir;
my $repo-dir = $dest.add( '.repo' ).mkdir;

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


my $repo = CompUnit::Repository::Installation.new: prefix => $repo-dir;

CompUnit::RepositoryRegistry.register-name: 'pakku', $repo;
CompUnit::RepositoryRegistry.use-repository: $repo, current => $*REPO.next-repo;


for @dep -> $dep {

  my $dep-name =  $dep.split('&').head;

  🐞 "SPC: ｢$dep-name｣";

  my $meta-url = "http:/recman.pakku.org/recommend?name=$dep";

  🤓 "FTC: ｢$meta-url｣";

  my $meta = run 'curl', '-s', $meta-url, :out;

  my %meta = Rakudo::Internals::JSON.from-json($meta.out(:close).slurp);

  my $inst-dep = $repo.candidates( %meta<name> ).head;

  with $inst-dep {

    next if %meta<version>.Version ~~ $inst-dep.meta<ver>.Version; 

  }

  my $long-name = "%meta<name>:ver<%meta<version>>:auth<%meta<auth>>:api<%meta<api>>";

  my $src-path = $dep-dir.add: $dep-name;

  my $archive-path = "$src-path.tar.gz".IO;

  🤓 "FTC: ｢$archive-path｣";

  my $curl = run 'curl', '-s', '-o', $archive-path, %meta<recman-src>;

  mkdir $src-path;

  my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';

  $repo.install: :force, Distribution::Path.new: $src-path;

  🦋 "ADD: ｢$long-name｣";
}

my $cmd = qq:to/CMD/;

use lib {$repo.path-spec.raku};
use lib {$src.Str.raku};

use Pakku;

@*ARGS = «
  verbose $verbose
  { $pretty ?? 'pretty' !! 'nopretty' }
  add
  force
  to "$repo-dir"
  "$src"
»;

Pakku.new.fun;

CMD

run ~$*EXECUTABLE, '-e', $cmd;

my $cnf-src = $src.add:  'resources/pakku.cnf';
my $cnf-dst = $dest.add: 'pakku.cnf';

unless $cnf-dst.e {

  run 'cp', $cnf-src, $cnf-dst;

  🦋 "CNF: ｢$cnf-dst｣";

}

my $bin-content = q:to/END/;
  #!/usr/bin/env raku

  BEGIN {

    my $prefix = $*PROGRAM.resolve.parent( 2 ) ~ '/.repo';

    my $core = CompUnit::RepositoryRegistry.repository-for-name: 'core';

    my $pakku = CompUnit::Repository::Installation.new: :$prefix;

    CompUnit::RepositoryRegistry.register-name: 'pakku', $pakku;

    CompUnit::RepositoryRegistry.use-repository: $pakku, current => $core;

  }

  use Pakku;

  Pakku.new.fun;

  END

my $bin = $bin-dir.add: 'pakku';

$bin.spurt: $bin-content;

$bin.IO.chmod(0o755);

🦋 "BIN: ｢$bin｣";

LEAVE {

 require File::Directory::Tree;

 my &rm = ::("File::Directory::Tree::EXPORT::DEFAULT::&rmtree");

 rm $dep-dir;

}


