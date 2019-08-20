use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::RecMan;
use Pakku::Fetcher;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;
  also does Pakku::Fetcher;


has %!config;
has Pakku::RecMan $!recman;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );
  
  %!config = $cnf.ast.merge: $cmd.ast;

 
  given %!config<cmd> {

    my @source = flat %!config<pakku><source>;

    when 'add' {
      $!recman = Pakku::RecMan.new: :@source;
      self.add(    |%!config<add> );
    }

    when 'remove' {
      self.remove(    |%!config<remove> );
    }

    when 'search' {
      $!recman = Pakku::RecMan.new: :@source;
      self.search(    |%!config<search> );
    }

  }
 
}

method search ( :@dist! ) {

  $!recman.search: :@dist;

}

method add ( :@dist! ) {

  my @cand = $!recman.recommend: :@dist;

  for @cand -> %cand {

    my $distdir = self.fetch: src => %cand<source-url>;

    my $dist = Pakku::Dist.new: |%cand;

    my $repo = CompUnit::RepositoryRegistry.repository-for-name('site');

    indir($distdir, { $repo.install($dist) });

  }
  #say @cand;

}

method remove ( ) {

}

