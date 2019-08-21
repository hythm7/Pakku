use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::RecMan;
use Pakku::Fetcher;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;
  also does Pakku::Fetcher;


has %!config;

has Pakku::Ecosystem     $!ecosystem;
has Pakku::RecMan        $!recman;
has CompUnit::Repository $!repo;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!config = $cnf.ast.merge: $cmd.ast;

  my $repo   = %!config<pakku><repo> // "inst#$*HOME/.pakku";
  my @source = flat %!config<pakku><source>;

  #$!repo = CompUnit::RepositoryRegistry.repository-for-spec: $repo, name => 'pakku', next-repo => $*REPO;
  $!repo = CompUnit::RepositoryRegistry.repository-for-name: 'site';

  $!ecosystem = Pakku::Ecosystem.new: :@source;
  $!recman    = Pakku::RecMan.new:    :$!ecosystem;

  given %!config<cmd> {

    self.add(    |%!config<add> )    when 'add';

    self.remove( |%!config<remove> ) when 'remove';

    self.search( |%!config<search> ) when 'search';
  }

}

method search ( :@ident! ) {

  $!recman.recommend: :@ident;

}

method add ( :@ident! ) {

  my @candsrc = $!recman.recommend: :@ident;

  for @candsrc -> $src {

    my $distdir = self.fetch: :$src;

    my %meta = from-json slurp $distdir.add: 'META6.json';

    my $dist = Pakku::Dist.new: |%meta;

    indir( $distdir, { $!repo.install( $dist ) } );

  }

}

method remove ( :@ident! ) {

   # Bug: Only %meta<files> getting deleted

   for @ident -> $ident {

    my $dist = $!repo.candidates( $ident.name ).head;

    $!repo.uninstall: $dist;


  }



}

