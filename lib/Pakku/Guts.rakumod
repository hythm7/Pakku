use X::Pakku;
use Pakku::Log;
use Pakku::Help;
use Pakku::Meta;
use Pakku::Spec;
use Pakku::Repo;
use Pakku::Tester;
use Pakku::Builder;
use Pakku::Fetcher;
use Grammar::Pakku::Cnf;
use Grammar::Pakku::Cmd;
use Pakku::RecMan::Client;

unit role Pakku::Guts;
  also does Pakku::Help;

has      %!cnf;
has Bool $!dont;
has Bool $!yolo;
has      @!ignored;

has Pakku::Log            $!log;
has Pakku::Fetcher        $!fetcher;
has Pakku::Builder        $!builder;
has Pakku::Tester         $!tester;
has Pakku::RecMan::Client $!recman;


multi method satisfy ( :@spec! ) {

  🐞 "SPC: {｢@spec｣}";

  my $meta =
    @spec.map( -> $spec {

      my $meta = try samewith :$spec;

      if $meta {

        🐞 "MTA: ｢$meta｣"; 

        return $meta;

      }

    } );

  die X::Pakku::Meta.new: meta => @spec unless $meta;;

}


multi method satisfy ( Pakku::Spec::Raku:D :$spec! ) {

  🐞 "SPC: ｢$spec｣";

  # TODO: revisit
  my $meta = 
    $spec.prefix
      ?? try Pakku::Meta.new: $spec.prefix
      !! try Pakku::Meta.new: $!recman.recommend: :$spec;

  die X::Pakku::Meta.new: meta => $spec unless $meta;

  if $meta {

    🐞 "MTA: ｢$meta｣"; 

    $meta;
  }

}


multi method satisfy ( Pakku::Spec::Bin:D :$spec! ) {

  die X::Pakku::Spec.new: :$spec;

}

multi method satisfy ( Pakku::Spec::Native:D :$spec! ) {

  die X::Pakku::Spec.new: :$spec;

}

multi method satisfied ( :@spec! --> Bool:D ) {

  so @spec.first( -> $spec { samewith :$spec } ); 

}

multi method satisfied ( Pakku::Spec::Raku:D :$spec! --> Bool:D ) {


  return True if $spec.name ~~ any @!ignored;

  return so $*repo.candies( $spec );

}


multi method satisfied ( Pakku::Spec::Bin:D :$spec! --> Bool:D ) {

  use File::Which;

  return False unless which $spec.name;

  True;
}

multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  use NativeLibs;

  my $name = $spec.name;
  my $ver  = $spec.ver;

  return False unless NativeLibs::Loader.load: NativeLibs::cannon-name( $name, |( $ver if $ver ) );
 
  True;
}


multi method get-deps ( Pakku::Meta:D $meta, :$deps ) {

  #TODO: Revisit if issues when required
    # two different versions of same dependnecy.
    # may be store meta in %visited and 
    # then Meta ~~ Spec 

  state %visited;
  
  $meta.deps: :$deps

    ==> grep( -> $spec { not ( %visited{ $spec.name } or self.satisfied: :$spec )   } )

    ==> map(  -> $spec { self.satisfy: :$spec } )

    ==> my @meta-deps;

    return Empty unless +@meta-deps;

    my @dep;

    for @meta-deps -> $dep {

      next if %visited{ $dep.name };

      %visited{ $dep.name } = True;

      @dep.append: flat self.get-deps( $dep, :$deps), $dep
    }

    @dep;
}

multi method get-deps( Pakku::Spec:D $spec, :$deps ) {

  return Empty;

}


submethod BUILD ( ) {

  my $default-cnf = %?RESOURCES<pakku.cnf>.IO;
  my $user-cnf    = $*REPO.Str.IO.parent.add: 'pakku.cnf';

  my $pakku-cnf   = $user-cnf.e ?? $user-cnf !! $default-cnf;

  my $cnf = Grammar::Pakku::Cnf.parsefile( $pakku-cnf, actions => Grammar::Pakku::CnfActions.new );

  die X::Pakku::Cnf.new( cnf => $pakku-cnf ) unless $cnf;

  my $cmd = Grammar::Pakku::Cmd.parse( @*ARGS, actions => Grammar::Pakku::CmdActions );

  die X::Pakku::Cmd.new( cmd => @*ARGS ) unless $cmd;

  %!cnf =  hashmerge $cnf.made, $cmd.made;

  my @url     = %!cnf<recman>.flat;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my $pretty  = %!cnf<pakku><pretty>  // True;

  $!dont = %!cnf<pakku><dont> // False;
  $!yolo = %!cnf<pakku><yolo> // False;

  $!log  = Pakku::Log.new: :$verbose, :$pretty, cnf => %!cnf<log>;

  my Pakku::Repo $*repo .= new: %!cnf<add remove pack list>.first( *<repo> )<repo>;

  $!recman  = Pakku::RecMan::Client.new: :@url;

  $!fetcher = Pakku::Fetcher.new;

  @!ignored = <Test NativeCall nqp>;

  given %!cnf<cmd> {

    when 'add'      { self.add:      |%!cnf<add>      }

    when 'build'    { self.build:    |%!cnf<build>    }

    when 'test'     { self.test:     |%!cnf<test>     }

    when 'remove'   { self.remove:   |%!cnf<remove>   }

    when 'checkout' { self.checkout: |%!cnf<checkout> }

    when 'pack'     { self.pack:     |%!cnf<pack>     }

    when 'list'     { self.list:     |%!cnf<list>     }
    
    when 'help'     { 🦋 self.help:  |%!cnf<help>     }
  }

  CATCH {

    when X::Pakku::Cnf {

      Pakku::Log.new: :4verbose, :pretty;

      💀 .message;

    }

    when X::Pakku::Cmd {

      Pakku::Log.new: :4verbose, :pretty;

      💀 .message;

    }

    when X::Pakku {

      💀 .message;

      if $!yolo {

        🔔 'YOL: ｢¯\_(ツ)_/¯｣';

        .resume;

      }

      nofun;
    }

  }

}

# Stolen from Hash::Merge:cpan:TYIL to fix #6
sub hashmerge ( %merge-into, %merge-source ) {

  for %merge-source.keys -> $key {
    if %merge-into{$key}:exists {
      given %merge-source{$key} {
        when Hash {
          hashmerge %merge-into{$key}, %merge-source{$key};
        }
        default { %merge-into{$key} = %merge-source{$key} }
      }
    }
    else {
      %merge-into{$key} = %merge-source{$key};
    }
  }

  %merge-into;
}

