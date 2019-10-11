use JSON::Fast;
use Hash::Merge::Augment;
use Terminal::ANSIColor;

use Pakku::Log;
use Pakku::Help;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Builder;
use Pakku::Tester;
use Pakku::DepSpec;
use Pakku::Dist::Perl6::Path;
use Pakku::Dist::Perl6::Inst;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;
  also does Pakku::Help;

has %!cnf;

has Pakku::Log           $!log;
has %!installed;
has Pakku::Dist::Perl6   @!installed;
has Pakku::Fetcher       $!fetcher;
has Pakku::Builder       $!builder;
has Pakku::Tester        $!tester;
has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;
has CompUnit::Repository @!inst-repo;

has Bool $!dont;


method add (

  :@what!,

  CompUnit::Repository :$into = $!repo,

  :%deps = %( :requires, :recommends ),
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {

    my @repo = $into.repo-chain.grep( CompUnit::Repository::Installation );

    🐛 "Pakku: Processing [{@what}]";

    unless $force {

      🐛 "Pakku: Filtering installed [{@what}]";

      @what .= grep( -> $what {


        🐛 "Pakku: Checking if there are installed dists matching [$what]";

        my @inst = self.installed: $what, :@repo;

        if @inst {

          🐛 "Pakku: Found installed dists [{@inst}] matching [$what]";

          🐛 "Pakku: Will not install [$what] unless forced";

          🐛 "Pakku: Removing spec [$what] from list";

        }

        else {

          🐛 "Pakku: Found no installed dists matching [$what]";

        }

        not @inst;

      } );

    }


  unless @what {

    🐛 "Pakku: Nothing remaning to install";

    allgood;

    return;

  }


  🐛 "Pakku: Asking Eco recommendations for [{@what}]";

  my @candies = $!ecosystem.recommend: :@what, :%deps;


  unless $force {

    🐛 "Pakku: Filtering recommended dists: {@candies}";

    @candies .= map(
      *.grep( -> $dist {

        🐛 "Pakku: Checking if dist [$dist] is already installed";

        my Bool:D $inst =  so any self.installed: $dist, :@repo;

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


  🐛 "Pakku: Filtering non Perl6 distributions";

  @candies .= map( *.grep( Pakku::Dist::Perl6 ));

  🦋 "Pakku: ✓ Candies to be installed: [{@candies}]";


  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Perl6::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                   } ) } )
    <== map( {       .map( -> $cand { $cand.?prefix || $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  my $repo = @repo.head;

  @dists.map( -> @dist {

    for @dist -> $dist {

      $!builder.build: :$dist if $build;
      $!tester.test:   :$dist if $test;

      unless $!dont {
        $repo.install: $dist, :$force;
        🦋 "Pakku: ✓ Installed [$dist] to repo [{$repo.name}]";
      }

    }

  } );

  ofun;

  CATCH {

    when X::Pakku::Ecosystem::NoCandy {

      ☠ .message;

      nofun;

    }

    when X::LibCurl {

      ☠ .message;

      nofun;

    }

    when X::Pakku::Build::Fail {

      ☠ .message;

      nofun;

    }

    when X::Pakku::Test::Fail {

      ☠ .message;

      nofun;

    }

    when X::Pakku::Dist::Bin::NotFound {

      ☠ .message;

      nofun;

    }
  }

}

method build ( :@what! ) {

  🐛 "Pakku: Asking Eco recommendations for [{@what}]";

  my @candies = $!ecosystem.recommend: :@what;

  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Perl6::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                   } ) } )
    <== map( {       .map( -> $cand { $cand.?prefix || $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  @dists.map( -> @dist {

    for @dist -> $dist {

      unless $!dont {
        $!builder.build: :$dist;
        🦋 "Pakku: ✓  Built [$dist]";
      }

    }

  } );

  ofun;

}

method test ( :@what! ) {

  🐛 "Pakku: Asking Eco recommendations for [{@what}]";

  my @candies = $!ecosystem.recommend: :@what;

  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Perl6::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                   } ) } )
    <== map( {       .map( -> $cand { $cand.?prefix || $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  @dists.map( -> @dist {

    for @dist -> $dist {

      unless $!dont {
        $!tester.test: :$dist;
        🦋 "Pakku: ✓ Test succeeded for [$dist]";
      }

    }

  } );

  ofun;

}

method check ( :@what! ) {
  # TODO: custom destination

  🐛 "Pakku: Asking Eco recommendations for [{@what}]";

  my @candies = $!ecosystem.recommend: :@what;

  my @path
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                   } ) } )
    <== map( {       .map( -> $cand { $cand.?prefix || $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  @path.map( -> @path {

    for @path -> $path {

      unless $!dont {
        qqx{ cp -rp $path $*CWD };
        🦋 "Pakku: ✓ [{$path.basename}] success";
      }

    }

  } );

  ofun;

}


method remove (

  :@what!,
  CompUnit::Repository :$from = $!repo,

) {

    my @repo = $from.repo-chain.grep( CompUnit::Repository::Installation );


  my @dist = flat @what.map( -> $what {

    my @inst = flat self.installed: $what, :@repo;

    🐛 "Found no installed dists matching [$what]" unless @inst;

    @inst;

  } );

  unless @dist {

    allgood;

    return;

  }

  @repo.map( -> $repo {

    for @dist -> $dist {

      # Temp workaround for rakudo issue #3153
      $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;


      $repo.uninstall: $dist;

      🦋 "Pakku: ✓ Removed [$dist] from [{$repo.name}]";

    }

  } );


  ofun;
}


method list (

  :@what,

  Bool:D :$details = False,
  Bool:D :$remote  = False,
  Bool:D :$local   = !$remote,

  CompUnit::Repository:D  :$repo = $!repo,

) {

  my @repo = $repo.repo-chain.grep( CompUnit::Repository::Installation );


  my @dist;

  if $local {

    # TODO: ⚠ if no dist
    @what
      ?? @dist.append: @what.map( -> $what { flat self.installed: $what, :@repo } ).flat
      !! (
           @dist
             <== grep( *.defined )
             <== gather %!installed{ @repo.map( *.name ) }.deepmap: *.take
         )
      ;

  }

  else {

    @what
      ?? @dist.append: $!ecosystem.recommend( :@what, :!deps ).flat
      !! @dist.append: $!ecosystem.list-dists;

  }

  my Str $list = @dist.grep( *.defined ).map( *.gist: :$details ).join( "\n" );

  🦋 $list if $list;

  ofun;

  CATCH {

    when X::Pakku::Ecosystem::NoCandy {

      ⚠ .message;

      🐛 "Pakku: Proceeding anyway";

      .resume

    }

  }
}


# TODO: Rewrite these methods
# TODO: use @!repo instead

multi submethod installed ( Pakku::DepSpec::Perl6:D $depspec, :@repo! ) {

  return @repo.map( -> $repo { self.installed: :$repo, $depspec } ).grep( *.so );

}

multi submethod installed ( IO::Path:D $path, :@repo!) {

  my $dist = Pakku::Dist::Perl6::Path.new: $path;

  my $depspec = Pakku::DepSpec.new: $dist.Str;

  self.installed: $depspec, :@repo;

}

multi submethod installed ( Pakku::Dist::Perl6:D $dist, :@repo! ) {

  my $depspec = Pakku::DepSpec.new: $dist.Str;

  self.installed: $depspec, :@repo;

}

multi submethod installed ( Pakku::Dist::Bin:D $dist, :@repo! ) {

  my $name = $dist.name;

  my $path = qqx{ which $name };

  die X::Pakku::Dist::Bin::NotFound.new: name => $dist.name unless $path;

  True;

}

multi submethod installed ( Pakku::DepSpec::Perl6:D $depspec, :$repo! ) {

  my @inst
    <== grep( -> $inst { $inst ~~ $depspec })
    <== grep( *.defined )
    <== gather %!installed{ $repo.name }{ $depspec.short-name }.deepmap: *.take;

  @inst;

}



# TODO: Instead of nap see if can await for all Log msgs

submethod BUILD ( ) {

  my $default-cnf = %?RESOURCES<pakku.cnf>.IO;
  my $user-cnf    = $*HOME.add: <.pakku/pakku.cnf>;

  my $pakku-cnf = $user-cnf.e ?? $user-cnf !! $default-cnf;


  my $cnf = Pakku::Grammar::Cnf.parsefile( $pakku-cnf, actions => Pakku::Grammar::Cnf::Actions.new );

  die X::Pakku::Parse::Cnf.new( cnf => $pakku-cnf ) unless $cnf;

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  die X::Pakku::Parse::Cmd.new( cmd => @*ARGS ) unless $cmd;

  %!cnf = $cnf.ast.merge: $cmd.ast;

  my @source  = %!cnf<source>.flat;
  my $update  = %!cnf<pakku><update>;
  my $verbose = %!cnf<pakku><verbose> // 4;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;


  $!dont  = %!cnf<pakku><dont> // False;

  $!log     = Pakku::Log.new: :$verbose, :$pretty, cnf => %!cnf<log>;


  $!fetcher = Pakku::Fetcher;
  $!builder = Pakku::Builder;
  $!tester  = Pakku::Tester;


  $!repo = $repo;

  @!inst-repo = $!repo.repo-chain.grep( CompUnit::Repository::Installation );

  @!inst-repo.map( -> $repo {

    eager $repo.installed
      ==> map( -> $dist { Pakku::Dist::Perl6::Inst.new: meta => $dist.meta })
      ==> map( -> $dist { %!installed{$repo.name}{$dist.name}.push: $dist } );
  } );



  given %!cnf<cmd> {

    when 'add' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source;

      self.add:    |%!cnf<add>;

    }

    when 'build' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source;

      self.build:    |%!cnf<build>;

    }

    when 'test' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source;

      self.test:    |%!cnf<test>;

    }


    when 'remove' {

      self.remove: |%!cnf<remove>;

    }

    when 'check' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source;

      self.check: |%!cnf<check>;

    }

    when 'list' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source if %!cnf<list><remote>;

      self.list:   |%!cnf<list>;

    }

    when 'help' {

      🦋 self.help:   |%!cnf<help>;

    }
  }

  CATCH {

    when X::Pakku::DepSpec::CannotParse {

      ☠ .message;

      nofun;

    }

    when X::Pakku::Parse::Cnf {

      Pakku::Log.new: :4verbose, :pretty;

      ☠ .message;

    }

    when X::Pakku::Parse::Cmd {

      Pakku::Log.new: :4verbose, :pretty;

      ☠ .message;

    }


  }

}
