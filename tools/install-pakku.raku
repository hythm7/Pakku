#!/usr/bin/env raku

sub MAIN ( IO( ) :$dest = $*HOME.add( '.pakku' ).cleanup ) {

  my $src      = $?FILE.IO.parent(2);

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


  my $pakku-repo = CompUnit::Repository::Installation.new: prefix => $repo-dir;

  CompUnit::RepositoryRegistry.register-name: 'pakku', $pakku-repo;
  CompUnit::RepositoryRegistry.use-repository: $pakku-repo;


  for @dep -> $dep {
  
    my $dep-name =  $dep.split('&').head;
  
    say "Installing Pakku dependency [$dep-name]";
  
    my $meta-url = "http:/recman.pakku.org/meta?name=$dep";
  
    my $meta = run 'curl', '-s', $meta-url, :out;
  
    my $src-url = Rakudo::Internals::JSON.from-json($meta.out(:close).slurp)<recman-src>;
  
    my $src-path = $dep-dir.add: $dep-name;
  
    my $archive-path = "$src-path.tar.gz".IO;
  
    unlink $archive-path;
  
    my $curl = run 'curl', '-s', '-o', $archive-path, $src-url;
  
    mkdir $src-path;
  
    my $tar = run 'tar', 'xf', $archive-path, '-C', $src-path, '--strip-components=1';
  
    $pakku-repo.install: :force, Distribution::Path.new: $src-path
  
  }

  say "Installing Pakku...";
  
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
  
  run $pakku-bin, 'verbose debug', 'add', 'force', 'to', $repo-dir,  $src;
  
  say "Pakku installed to ｢$pakku-bin｣";

}
