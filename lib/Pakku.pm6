use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Log;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Builder;
use Pakku::Tester;
use Pakku::Specification;
use Pakku::Distribution::Path;
use Pakku::Distribution::Installed;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;

has %!cnf;

has Pakku::Log           $!log;
has Pakku::Distribution  %!installed;
has Pakku::Distribution  @!installed;
has Pakku::Fetcher       $!fetcher;
has Pakku::Builder       $!builder;
has Pakku::Tester        $!tester;
has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;

submethod BUILD ( ) {

  self!init;

  CATCH {  exit 1 when X::Pakku }
}

method add (

  :@spec!,
  :$into,
  Bool:D :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {


  @spec .= grep( -> $spec { not self.installed: :$spec } ) unless $force;


  unless @spec {

    $!log.info: "Saul Goodman!";

    return;

  }


  my @cand = flat $!ecosystem.recommend: :@spec, :$deps;

  unless @cand {

    $!log.error: "No candies!";

    return;

  }

  $!log.debug: "Found: {~@cand}";


  unless $force {

    $!log.debug: "Filtering installed candies: {@cand}";

    @cand .= grep( -> $dist { not self.installed: :$dist } );

    $!log.debug: "Candies to be installed: {@cand}";

  }

  my @dist
    <== map( -> $path { Pakku::Distribution::Path.new: $path } )
    <== $!fetcher.fetch( @cand».source-url );

  my $repo = $into // $!repo;
  $!log.debug: "Installation repo is $repo";

  for @dist -> $dist {

    $!builder.build: :$dist if $build;
    $!tester.test:   :$dist if $test;

    $!log.debug: "Installing $dist";
    $repo.install: $dist, :$force;

  }

}

method remove ( :@spec!, :$from, :$deps ) {

  my $repo = $from // $!repo;

  for @spec -> $spec {

    my $dist = $repo.candidates( $spec ).head;

    # Temp workaround for rakudo issue #3153
    $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;

    $repo.uninstall: $dist if so $dist;

  }
}

method search ( :@spec! ) {

  $!ecosystem.recommend: :@spec;

}


multi submethod installed ( Pakku::Specification:D :$spec! ) {

  my @cand;

  my $name = $spec.short-name;

  return flat %!installed{$name} if so %!installed{$name};

  return @!installed.grep( *.provides: :$name).grep( * ~~ $spec).sort( *.version );

}

multi submethod installed ( Pakku::Distribution:D :$dist! --> Bool ) {

  return True if so %!installed{$dist.name};


  return True if @!installed.grep( -> $inst { $dist.name ~~ $inst.provides } );

  #return True if @!installed.grep: *.provides: name => $dist.name;

  return False;

}

submethod !init ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!cnf = $cnf.ast.merge: $cmd.ast;

  my @source  = %!cnf<source>.flat;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;

  $!log     = Pakku::Log.new:     :$verbose, :$pretty;
  $!fetcher = Pakku::Fetcher.new: :$!log;
  $!builder = Pakku::Builder.new: :$!log;
  $!tester  = Pakku::Tester.new:  :$!log;


  $!repo = $repo;
  $!repo.repo-chain
     ==> grep( CompUnit::Repository::Installation )
     ==> map( *.installed )
     ==> flat()
     ==> map( -> $dist {
         Pakku::Distribution::Installed.new: meta => $dist.meta, prefix => $dist.prefix
       })
     ==> @!installed;

     %!installed = @!installed.map( -> $dist { $dist.name => $dist } );


  $!ecosystem = Pakku::Ecosystem.new: :$!log, :@source;

  given %!cnf<cmd> {

    self.add:    |%!cnf<add>    when 'add';
    self.remove: |%!cnf<remove> when 'remove';
    self.search: |%!cnf<search> when 'search';
  }

}
