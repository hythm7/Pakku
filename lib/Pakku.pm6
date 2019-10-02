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
use Pakku::Dist::Inst;

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

has Bool $!dont;

has Str $!ofun;
has Str $!nofun;
has Str $!allgood;

submethod BUILD ( ) {

  self!init;

 }

method add (

  :@what!,

  CompUnit::Repository :$into = $!repo,

  Bool:D :$deps  = True,
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

    self.allgood;

    return;

  }


  🐛 "Pakku: Asking Eco recommendations for [{@what}]";

  my @candies = $!ecosystem.recommend: :@what, :$deps;


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

  🦋 "Pakku: Candies to be installed: [{@candies}]";


  my @dists
    <== map( {       .map( -> $path { Pakku::Dist::Path.new: $path      } ) } )
    <== map( { eager .map( -> $src  { $!fetcher.fetch: :$src                    } ) } )
    <== map( {       .map( -> $cand { $cand.?prefix || $cand.source-url || $cand.support<source> } ) } )
    <== @candies;


  my $repo = @repo.head;

  @dists.map( -> @dist {

    for @dist -> $dist {

      $!builder.build: :$dist if $build;
      $!tester.test:   :$dist if $test;

      unless $!dont {
        $repo.install: $dist, :$force;
        🦋 "Pakku: Installed [$dist] to repo [{$repo.name}]";
      }

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

    when X::Pakku::Build::Fail {

      ☠ .message;

      self.Nofun;

    }
  }

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

method help ( Str:D :$cmd ) {

  given $cmd {

    when 'add'    { put 'help add' }
    when 'remove' { put 'help remove' }
    when 'list'   { put 'help list' }

    default { put 'help' }

  }

}

# TODO: samewith
multi submethod installed ( Pakku::Spec:D $spec, :@repo! ) {

  return @repo.map( -> $repo { self.installed: :$repo, $spec } ).grep( *.so );

}


multi submethod installed ( IO::Path:D $path, :@repo!) {

  my $dist = Pakku::Dist::Path.new: $path;

  my $spec = Pakku::Spec.new: spec => $dist.Str;

  nextwith: :@repo, $spec;

}

multi submethod installed ( Pakku::Dist:D $dist, :@repo! ) {

  my $spec = Pakku::Spec.new: spec => $dist.Str;

  nextwith: :@repo, $spec;

}

multi submethod installed ( Pakku::Spec:D $spec, :$repo! ) {

  my @inst
    <== grep( -> $inst { $inst ~~ $spec })
    <== grep( *.defined )
    <== gather %!installed{ $repo.name }{ $spec.name }.deepmap: *.take;

  @inst;

}



# TODO: Instead of nap see if can await for all Log msgs
submethod Ofun    ( --> Bool:D ) { sleep .1; put $!ofun    };
submethod Nofun   ( --> Bool:D ) { sleep .1; put $!nofun   };
submethod allgood ( --> Bool:D ) { sleep .1; put $!allgood };

submethod !init ( ) {

  my $default-cnf = %?RESOURCES<pakku.cnf>.IO;
  my $user-cnf    = $*HOME.add: <.pakku/pakku.cnf>;

  my $pakku-cnf = $user-cnf.e ?? $user-cnf !! $default-cnf;


  my $cnf = Pakku::Grammar::Cnf.parsefile( $pakku-cnf, actions => Pakku::Grammar::Cnf::Actions.new );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!cnf = $cnf.ast.merge: $cmd.ast;

  say %!cnf;

  my @source  = %!cnf<source>.flat;
  my $update  = %!cnf<pakku><update>;
  my $verbose = %!cnf<pakku><verbose> // 4;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;

  $!dont  = %!cnf<pakku><dont> // False;

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
      ==> map( -> $dist { Pakku::Dist::Inst.new: meta => $dist.meta })
      ==> map( -> $dist { %!installed{$repo.name}{$dist.name}.push: $dist } );
  } );



  given %!cnf<cmd> {

    when 'add' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source;

      self.add:    |%!cnf<add>;

    }

    when 'remove' {

      self.remove: |%!cnf<remove>;

    }

    when 'list' {

      $!ecosystem = Pakku::Ecosystem.new: :$update, :@source if %!cnf<list><remote>;

      self.list:   |%!cnf<list>;

    }

    when 'help' {

      self.help:   |%!cnf<help>;

    }
  }

  CATCH {

    when X::Pakku::Spec::CannotParse {

      ☠ .message;

      self.Nofun;

    }

  }



}
