use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::RecMan;
use Pakku::Fetcher;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;
  also does Pakku::Fetcher;


has %!config;

has Pakku::Ecosystem $!ecosystem;
has Pakku::RecMan    $!recman;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );
  
  %!config = $cnf.ast.merge: $cmd.ast;

  my @source = flat %!config<pakku><source>;

  $!ecosystem = Pakku::Ecosystem.new: :@source;
  $!recman    = Pakku::RecMan.new:    :$!ecosystem;
 
  given %!config<cmd> {

    self.add(    |%!config<add> )    when 'add';

    self.remove( |%!config<remove> ) when 'remove';

    self.search( |%!config<search> ) when 'search';
  }
 
}

method search ( :@dist! ) {

  $!recman.recommend: :@dist;

}

method add ( :@dist! ) {

  my @cand = $!recman.recommend: :@dist;

  for @cand -> %cand {

    my $distdir = self.fetch: src => %cand<source-url>;

    my $dist = Pakku::Dist.new: |%cand;

    my $repo = CompUnit::RepositoryRegistry.repository-for-name('site');

    indir($distdir, { $repo.install($dist) });

  }

}

method remove ( ) {

}

