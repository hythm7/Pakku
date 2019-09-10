use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Log;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Builder;
use Pakku::Tester;
use Pakku::Spec;
use Pakku::Dist::Path;
use Pakku::Dist::Installed;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;

has %!cnf;

has Pakku::Log           $!log;
has %!installed;
has Pakku::Dist          @!installed;
has Pakku::Fetcher       $!fetcher;
has Pakku::Builder       $!builder;
has Pakku::Tester        $!tester;
has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;
has CompUnit::Repository @!inst-repo;

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

  CompUnit::Repository :$into = $!repo,

  Bool:D :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {

    my @repo = $into.repo-chain.grep( CompUnit::Repository::Installation );

    unless $force {

      @spec .= grep( -> $spec {

        my @installed = flat @spec.map( -> $spec { self.installed: :$spec, :@repo } );

        $!log.debug: "Found installed [{@installed}] matching spec [$spec]" if @installed;

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

    @candies .= map( *.grep( -> $dist { not self.installed: :@repo, :$dist } ) );

  }

  $!log.debug: "Candies to be installed: {@candies}";


  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                    } ) } )
    <== map( {       .map( -> $cand { $cand.source-url // $cand.support<source> } ) } )
    <== @candies;


  my $repo = @repo.head;

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

method remove (

  :@spec!,
  CompUnit::Repository :$from = $!repo,
  Bool:D :$deps

) {

    my @repo = $from.repo-chain.grep( CompUnit::Repository::Installation );

    my @dist = flat @spec.map( -> $spec { @repo.map( *.candidates: $spec ) } );

    unless @dist {

      $!log.info: "Saul Goodman";

      return;

    }

    @repo.map( -> $repo {


      for @dist -> $dist {
#
        # Temp workaround for rakudo issue #3153
        $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;

        $!log.debug: "Uninstalling $dist from {$repo.name}";

        $repo.uninstall: $dist;

      }

    } );

  $!log.ofun;
}


method list (

  :@spec,

  Bool:D :$info   = False,
  Bool:D :$remote = False,
  Bool:D :$local  = !$remote,

  CompUnit::Repository:D  :$repo = $!repo,

) {

  $!log.debug: "Looking for installed Dists";

  $!log.out: "{@!installed.map( *.Str ).join( "\n" )}";

  $!log.info: "-Ofun";

}


multi submethod installed ( :@repo!, Pakku::Spec:D :$spec! ) {

  return @repo.map( -> $repo { self.installed: :$repo, :$spec } );

}

multi submethod installed ( :$repo!, Pakku::Spec:D :$spec! ) {

  my @inst = %!installed{ $repo.name }{ $spec.name }.grep( *.defined ).grep( -> $inst { $inst ~~ $spec });

  return @inst if @inst;

  @inst = %!installed{ $repo.name }.grep( *.defined ).map( *.value.values ).flat.grep( -> $inst {

    $spec.name ~~ $inst.provides;

  } );

  return @inst;

}

multi submethod installed ( :@repo!, Pakku::Dist:D :$dist! ) {

  return so any @repo.map( -> $repo { self.installed: :$repo, :$dist } );

}

multi submethod installed ( :$repo!, Pakku::Dist:D :$dist! --> Bool ) {

  my $inst = %!installed{ $repo.name }{ $dist.name }.grep( *.defined ).first( -> $inst {
    $inst.name ~~ $dist.name
  } );

   return True if $inst;

  $inst = %!installed{$repo.name}.grep( *.defined ).map( *.value.values ).flat.first( -> $inst {

    $inst.name ~~ $dist.provides;

  } );

  return True if $inst;

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

  @!inst-repo = $!repo.repo-chain.grep( CompUnit::Repository::Installation );

  @!inst-repo.map( -> $repo {

    eager $repo.installed
      ==> map( -> $dist { Pakku::Dist::Installed.new: meta => $dist.meta, prefix => $dist.prefix })
      ==> map( -> $dist { %!installed{$repo.name}{$dist.name}.push: $dist } );
  } );


  $!ecosystem = Pakku::Ecosystem.new: :$!log, :@source;

  given %!cnf<cmd> {

    self.add:    |%!cnf<add>    when 'add';
    self.remove: |%!cnf<remove> when 'remove';
    self.list:   |%!cnf<list>   when 'list';
  }

}
