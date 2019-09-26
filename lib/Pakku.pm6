use JSON::Fast;
use Hash::Merge::Augment;
use Terminal::ANSIColor;

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

has Str $!ofun;
has Str $!nofun;
has Str $!allgood;

submethod BUILD ( ) {

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

    🐛 "Pakku: Processing specs [{@spec}]";

    unless $force {

      🐛 "Pakku: Filtering installed specs [{@spec}]";

      @spec .= grep( -> $spec {


        🐛 "Pakku: Checking if there are installed dists matching [$spec]";

        my @inst = self.installed: :$spec, :@repo;

        if @inst {

          🐛 "Pakku: Found installed dists [{@inst}] matching spec [$spec]";

          🐛 "Pakku: Will not install [$spec] unless forced";

          🐛 "Pakku: Removing spec [$spec] from specs list";

        }

        else {

          🐛 "Pakku: Found no installed dists matching spec [$spec]";

        }

        not @inst;

      } );

    }


  unless @spec {

    🐛 "Pakku: No specs remaning to install";

    self.allgood;

    return;

  }


  🐛 "Pakku: Asking Eco recommendations for specs [{@spec}]";

  my @candies = $!ecosystem.recommend: :@spec, :$deps;


  unless $force {

    🐛 "Pakku: Filtering recommended dists: {@candies}";

    @candies .= map(
      *.grep( -> $dist {

        🐛 "Pakku: Checking if dist [$dist] is already installed";

        my Bool:D $inst =  self.installed: :@repo, :$dist;

        if $inst {

          🐛 "Pakku: Removing dist [$dist] from recommended dists";
          🐛 "Pakku: Will not install dist [$dist] unless forced";

        }

        else {

          🐛 "Pakku: Dist [$dist] is not installed";

        }

        not $inst;

      } )
    );

  }

  🦋 "Pakku: Candies to be installed: [{@candies}]";


  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                    } ) } )
    <== map( {       .map( -> $cand { $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  my $repo = @repo.head;

  @dists.map( -> @dist {

    for @dist -> $dist {

      $!builder.build: :$dist if $build;
      $!tester.test:   :$dist if $test;

      $repo.install: $dist, :$force;
      🦋 "Installed [$dist] to repo [{$repo.name}]";

    }

  } );

  self.Ofun;

  CATCH {

    when X::Pakku::Ecosystem::NoCandy {

      ☠ .message;

      self.Nofun;

    }

    when X::LibCurl {

      ☠ .message;

      self.Nofun;

    }
  }

}

method remove (

  :@spec!,
  CompUnit::Repository :$from = $!repo,
  Bool:D :$deps

) {

    my @repo = $from.repo-chain.grep( CompUnit::Repository::Installation );


  my @dist = flat @spec.map( -> $spec {

    my @installed = flat self.installed: :$spec, :@repo;

    🐛 "Found no installed dists matching [$spec]" unless @installed;

    @installed;

  } );

  unless @dist {

    self.allgood;

    return;

  }

  @repo.map( -> $repo {

    for @dist -> $dist {

      # Temp workaround for rakudo issue #3153
      $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;


      $repo.uninstall: $dist;

      🦋 "Removed [$dist] from [{$repo.name}]";

    }

  } );



  self.Ofun;
}


method list (

  :@spec,

  Bool:D :$details = False,
  Bool:D :$remote  = False,
  Bool:D :$local   = !$remote,

  CompUnit::Repository:D  :$repo = $!repo,

) {

  my @repo = $repo.repo-chain.grep( CompUnit::Repository::Installation );

  🐛 "Pakku: Asking Eco recommendations for specs [{@spec}]";

  my @dist;

  if $local {

    # TODO: ⚠ if no dist
    @spec
      ?? @dist.append: @spec.map( -> $spec { flat self.installed: :@repo, :$spec } ).flat
      !! (
           @dist
             <== grep( *.defined )
             <== gather %!installed{ @repo.map( *.name ) }.deepmap: *.take
         )
      ;

  }

  else {

    @spec
      ?? @dist.append: $!ecosystem.recommend( :@spec, :!deps ).flat
      !! @dist.append: $!ecosystem.list-dists;

  }

  my Str $list = @dist.grep( *.defined ).map( *.gist: :$details ).join( "\n" );

  put $list if $list;

  self.Ofun;

  CATCH {

    when X::Pakku::Ecosystem::NoCandy {

      ⚠ .message;

      🐛 "Pakku: Proceeding anyway";

      .resume

    }

  }
}


multi submethod installed ( :@repo!, Pakku::Spec:D :$spec! ) {

  return @repo.map( -> $repo { self.installed: :$repo, :$spec } ).grep( *.so );

}

multi submethod installed ( :@repo!, Pakku::Dist:D :$dist! ) {

  my $spec = Pakku::Spec.new: spec => $dist.Str;

  return so any self.installed: :@repo, :$spec;

}

multi submethod installed ( :$repo!, Pakku::Spec:D :$spec! ) {

  my @inst
    <== grep( -> $inst { $inst ~~ $spec })
    <== grep( *.defined )
    <== gather %!installed{ $repo.name }{ $spec.name }.deepmap: *.take;

  return @inst;

}

# TODO: Instead of nap see if can await for all Log msgs
submethod Ofun    ( --> Bool:D ) { sleep .1; put $!ofun    };
submethod Nofun   ( --> Bool:D ) { sleep .1; put $!nofun   };
submethod allgood ( --> Bool:D ) { sleep .1; put $!allgood };

submethod !init ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions.new );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!cnf = $cnf.ast.merge: $cmd.ast;

  my @source  = %!cnf<source>.flat;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;

  $!log     = Pakku::Log.new: :$verbose, :$pretty, cnf => %!cnf<log>;

  $!ofun    = $pretty ?? colored( '-Ofun',        'bold 177' ) !! '-Ofun'; 
  $!nofun   = $pretty ?? colored( 'Nofun',        'bold 9'   ) !! '-Ofun'; 
  $!allgood = $pretty ?? colored( 'Saul Goodman', 'bold 177' ) !! 'Saul Goodman'; 


  $!fetcher = Pakku::Fetcher;
  $!builder = Pakku::Builder;
  $!tester  = Pakku::Tester;


  $!repo = $repo;

  @!inst-repo = $!repo.repo-chain.grep( CompUnit::Repository::Installation );

  @!inst-repo.map( -> $repo {

    eager $repo.installed
      ==> map( -> $dist { Pakku::Dist::Installed.new: meta => $dist.meta })
      ==> map( -> $dist { %!installed{$repo.name}{$dist.name}.push: $dist } );
  } );


  $!ecosystem = Pakku::Ecosystem.new: :$!log, :@source;

  given %!cnf<cmd> {

    self.add:    |%!cnf<add>    when 'add';
    self.remove: |%!cnf<remove> when 'remove';
    self.list:   |%!cnf<list>   when 'list';
  }

}
