use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Distribution;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;
  also does Pakku::Fetcher;


has %!config;
has Pakku::Distribution %!installed;
has Pakku::Distribution @!installed;

has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!config = $cnf.ast.merge: $cmd.ast;

  my $repo   = %!config<pakku><repo> // "inst#$*HOME/.perl6";
  my @source = flat %!config<pakku><source>;

  #$!repo = CompUnit::RepositoryRegistry.repository-for-spec: $repo, name => 'pakku', next-repo => $*REPO;
  $!repo = CompUnit::RepositoryRegistry.repository-for-name: $repo, next-repo => $*REPO;

  # @!installed = $!repo.repo-chain.grep( CompUnit::Repository::Installation ).flatmap( *.installed ).map( -> $d { Pakku::Distribution.new: |$d.meta });

  $!ecosystem = Pakku::Ecosystem.new: :@source;

  given %!config<cmd> {

    self.add(    |%!config<add> )    when 'add';

    self.remove( |%!config<remove> ) when 'remove';

    self.search( |%!config<search> ) when 'search';
  }

}

method add ( :@spec! ) {

  my @cand = $!ecosystem.recommend: :@spec;

  say "No candies!" unless @cand;

  for @cand -> $dist {

    my $prefix = self.fetch: src => $dist.source-url unless $dist.prefix;

    $dist.prefix = $prefix if $prefix;

    $!repo.install( $dist );

  }

}

method remove ( :@spec! ) {

   # Bug: Only %meta<files> getting deleted

   for @spec -> $spec {

    my $dist = $!repo.candidates( $spec ).head;

    $!repo.uninstall: $dist if so $dist;


  }
}

method search ( :@spec! ) {

  $!ecosystem.recommend: :@spec;

}

