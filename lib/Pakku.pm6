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

 CATCH {
    when X::Pakku {

      $!log.nofun;

    }
  }

  self!init;

 }

method add (

  :@spec!,
  :$into,
  Bool:D :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {


  unless $force {

    @spec .= grep( -> $spec {


      # TODO: per repo check to allow add into repo
      my @installed = self.installed: :$spec;

      $!log.debug: "Found installed [{@installed}] matching spec [$spec]";

      not @installed;

    } );

  }

  unless @spec {

    $!log.info: "Saul Goodman!";

    return;

  }


  my @candies = $!ecosystem.recommend: :@spec, :$deps;


  unless @candies {

    $!log.error: "No candies!";

    return;

  }


  $!log.debug: "Found: {@candies}";

  unless $force {

    $!log.debug: "Filtering installed candies: {@candies}";

    @candies .= map( *.grep( -> $dist { not self.installed: :$dist } ) );

  }

  $!log.debug: "Candies to be installed: {@candies}";


  my @dists
    <== map( {       .map( -> $path { Pakku::Distribution::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                    } ) } )
    <== map( {       .map( -> $cand { $cand.source-url // $cand.support<source> } ) } )
    <== @candies;


  my $repo = $into // $!repo;

  $!log.debug: "Installation repo: {$repo.name}";


  @dists.map( -> @dist {

    for @dist -> $dist {

      $!builder.build: :$dist if $build;
      $!tester.test:   :$dist if $test;

      $!log.debug: "Installing $dist";
      $repo.install: $dist, :$force;

    }

  } );

  $!log.ofun;
}

method remove ( :@spec!, :$from, :$deps ) {


  with $from {

    my @dist = flat @spec.map( -> $spec { $from.candidates: $spec } );

    unless @dist {

      $!log.info: "Saul Goodman";

      return;

    }

    @dist.map( -> $dist {

      # Temp workaround for rakudo issue #3153
      $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;

      $!log.debug: "Uninstalling $dist from {$from.name}";

      $!log.debug: "Uninstalling $dist";

      $from.uninstall: $dist;

      $!log.debug: "Uninstalled $dist from {$from.name}";


    } );
  }

  else {

    my @repo = $!repo.repo-chain.grep( CompUnit::Repository::Installation );
    my @dist = flat @spec.map( -> $spec { @repo.map( *.candidates: $spec ) } );

    unless @dist {

      $!log.info: "Saul Goodman";

      return;

    }

    @dist.map( -> $dist {

      # Temp workaround for rakudo issue #3153
      $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;

      $!log.debug: "Uninstalling $dist";

      @repo.map( *.uninstall: $dist );

      $!log.debug: "Uninstalled $dist from all repos";

    } );

  }


  $!log.ofun;
}


method list ( :@spec, :$info = False, :$remote = False ) {

  $!log.debug: "Looking for installed Distributions";

  $!log.out: "{@!installed.map( *.Str ).join( "\n" )}";

  $!log.info: "-Ofun";

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

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions.new );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!cnf = $cnf.ast.merge: $cmd.ast;

  my @source  = %!cnf<source>.flat;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;

  $!log     = Pakku::Log.new: :$verbose, :$pretty, cnf => %!cnf<log>;

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
    self.list:   |%!cnf<list>   when 'list';
  }

}
