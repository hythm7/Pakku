use X::Pakku;
use Pakku::Util;
use Pakku::Log;
use Pakku::Help;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Recman;
use Pakku::Repo;
use Pakku::Cache;
use Pakku::Test;
use Pakku::Build;
use Grammar::Pakku::Cnf;
use Grammar::Pakku::Cmd;

unit role Pakku::Guts;
  also does Pakku::Help;

has      %!cnf;

has Bool $!dont;
has Bool $!yolo;

has IO::Path $!cached;
has          @!ignored;

has Pakku::Log    $!log;
has Pakku::Build  $!builder;
has Pakku::Test   $!tester;
has Pakku::Cache  $!cache;
has Pakku::Recman $!recman;


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

  my $meta = try Pakku::Meta.new(
    ( $spec.prefix                           ) //
    ( $!cache .recommend: :$spec if $!cache  ) //
    ( $!recman.recommend: :$spec if $!recman )
  );

  die X::Pakku::Meta.new: meta => $spec unless $meta;

  if $meta {

    🐞 "MTA: ｢$meta｣"; 

    $meta;
  }

}


multi method satisfy ( Pakku::Spec::Bin:D :$spec! ) {

  die X::Pakku::Spec.new: :$spec;

  Empty;

}

multi method satisfy ( Pakku::Spec::Native:D :$spec! ) {

  die X::Pakku::Spec.new: :$spec;

  Empty;

}

multi method satisfied ( :@spec! --> Bool:D ) {

  so @spec.first( -> $spec { samewith :$spec } ); 

}

multi method satisfied ( Pakku::Spec::Raku:D :$spec! --> Bool:D ) {


  return True if $spec.name ~~ any @!ignored;

  return so $*repo.candies( $spec );

}


multi method satisfied ( Pakku::Spec::Bin:D :$spec! --> Bool:D ) {

  return False unless find-bin $spec.name;

  True;
}

multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  # TODO: Add native dir1:dir2 option to pakku
  # to include in search path;
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

    ==> grep( -> $spec { not ( %visited{ $spec.?name // any @$spec.map( *.name ) } or self.satisfied: :$spec )   } )

    ==> map(  -> $spec { self.satisfy: :$spec } )

    ==> my @meta-deps;

    return Empty unless +@meta-deps;

    my @dep;

    for @meta-deps -> $dep {

      my $name = $dep.name;

      next if %visited{ $name };

      %visited{ $name } = True;

      @dep.append: flat self.get-deps( $dep, :$deps), $dep
    }

    @dep;
}

multi method get-deps( Pakku::Spec:D $spec, :$deps ) {

  return Empty;

}

method fetch ( Pakku::Meta:D :$meta! ) {

  🐞 "FTC: ｢$meta｣";

  with $meta.path -> $path {

    🐞 "FTC: ｢$path｣";

    return $path;

  }

  my $dest = mkdir $!cached.IO.add( colondash $meta.name ).add( colondash ~$meta );

  my $url      = $meta.recman-src;
  my $download = $dest.add( colondash( ~$meta ) ~ '.tar.gz' ).Str;

  🤓 "FTC: ｢$url｣";

  $!recman.fetch: :$url :$download;

  extract archive => $download, dest => ~$dest;

  unlink $download;

  🤓 "FTC: ｢$dest｣";

  $dest;

}


method pakudo (
:$rakudo        = 'master',
IO::Path:D :$to = $*CWD,
--> IO::Path:D
) {


  🐞 "PAC: ｢Rakudo:$rakudo｣";

  my $build-dir  = $to.add( '.build' ).mkdir;
  my $rakudo-url = 'https://github.com/rakudo/rakudo',
  my $rakudo-src = $build-dir.IO.add: 'rakudo';

  my $clone = Proc::Async.new: «git clone -b "$rakudo" --single-branch "$rakudo-url" rakudo»;

  my $build = Proc::Async.new: «perl Configure.pl "--prefix=$to" --gen-moar --relocatable --make-install»; 

  react {

    whenever $clone.stdout.lines { 🤓 $^out }
    whenever $clone.stderr.lines { ❌ $^err }

    whenever $build.stdout.lines { 🤓 $^out }
    whenever $build.stderr.lines { ❌ $^err }

    whenever $clone.stdout.stable( 42 ) {
      🐞 "WAI: ｢{$clone.command}｣";
    }

    whenever $build.stdout.stable( 42 ) {
      🐞 "WAI: ｢{$build.command}｣";
    }

    whenever $clone.start( cwd => $build-dir, :%*ENV ) { 
      whenever $build.start( cwd => $rakudo-src, :%*ENV ) {
        done;
      }
    }
  }

  LEAVE  nuke-dir $build-dir;

  🦋 "PAC: ｢Rakudo:$rakudo｣";

  $to;

}


method fun ( ) {

  CATCH {
    when X::Pakku {

      💀 .message;

      if $!yolo {
        🔔 'YOL: ｢¯\_(ツ)_/¯｣';
        .resume;
      }

      nofun;
    }

    default {

      💀 .message;

      nofun;
    }
  }

  my $cmd = %!cnf<cmd>;

  self."$cmd"( |%!cnf{ $cmd } );

  ofun;

}

submethod BUILD ( :%!cnf! ) {

  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my %level   = %!cnf<log><level>     // {};

  my $cache   = %!cnf<pakku><cache>   // True;
  my $recman  = %!cnf<pakku><recman>  // True;
  my @url     = %!cnf<recman>.flat;

  $!dont      = %!cnf<pakku><dont>    // False;
  $!yolo      = %!cnf<pakku><yolo>    // False;


  $!cached  = $*PROGRAM.resolve.parent( 2 ).add( '.cache' );
  @!ignored = <Test NativeCall nqp>;


  $!log    = Pakku::Log.new: :$pretty :$verbose :%level;

  $!cache  = Pakku::Cache.new:  :$!cached if $cache;
  $!recman = Pakku::Recman.new: :@url     if $recman;

}

method new ( ) {

  CATCH {

    Pakku::Log.new: :3verbose :pretty;

    💀 .message;
    
    nofun;
  }

  my $pakku-dir   = $*PROGRAM.resolve.parent: 2;
  my $default-cnf = %?RESOURCES<pakku.cnf>.IO;
  my $user-cnf    = $pakku-dir.add: 'pakku.cnf';

  my $pakku-cnf   = $user-cnf.e ?? $user-cnf !! $default-cnf;

  my $cnf = Grammar::Pakku::Cnf.parsefile( $pakku-cnf, actions => Grammar::Pakku::CnfActions.new );

  die X::Pakku::Cnf.new( cnf => $pakku-cnf ) unless $cnf;

  my $cmd = Grammar::Pakku::Cmd.parse( @*ARGS, actions => Grammar::Pakku::CmdActions );

  die X::Pakku::Cmd.new( cmd => @*ARGS ) unless $cmd;

  my %cnf =  hashmerge $cnf.made, $cmd.made;

  self.bless: :%cnf;

}

