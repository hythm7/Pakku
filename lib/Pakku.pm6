use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Specification;
use Pakku::Distribution::Path;
use Pakku::Distribution::Installed;

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

  $!repo   = %!config<pakku><repo> // $*REPO;
  my @source = flat %!config<pakku><source>;

  $!repo.repo-chain
     ==> grep( CompUnit::Repository::Installation )
     ==> map( *.installed )
     ==> flat()
     ==> map( -> $dist { Pakku::Distribution::Installed.new: meta => $dist.meta })
     ==> @!installed;

     #say @!installed[7].resources;

  $!ecosystem = Pakku::Ecosystem.new: :@source;

  given %!config<cmd> {

    self.add(    |%!config<add> )    when 'add';

    self.remove( |%!config<remove> ) when 'remove';

    self.search( |%!config<search> ) when 'search';
  }

}

method add ( :@spec!, :$into, :$deps, :$force = False ) {

  my $repo = $into // $!repo; 

  my @cand = $!ecosystem.recommend: :@spec;

  say "No candies!" unless @cand;

  for @cand -> $dist {

    my $prefix = self.fetch: src => $dist.source-url;

    my $distpath = Pakku::Distribution::Path.new: $prefix;

    $repo.install( $distpath, :$force );

  }

}

method remove ( :@spec!, :$from, :$deps ) {

  # Bug: Only %meta<files> getting deleted

  my $repo = $from // $!repo; 

  for @spec -> $spec {

    my $dist = $!repo.candidates( $spec ).head;

    say $repo.uninstall: $dist if so $dist;


  }
}

method search ( :@spec! ) {

  $!ecosystem.recommend: :@spec;

}

