use X::Pakku;
use Pakku::Log;
use Pakku::Help;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Repo;
use Pakku::Cache;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Grammar::Pakku::Cnf;
use Grammar::Pakku::Cmd;

unit role Pakku::Core;
  also does Pakku::Help;

has      %!cnf;

has Bool $!dont;
has Bool $!yolo;

has Int  $!cores;

has IO::Path $!cached;
has IO::Path $!stage;

has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::Recman $!recman;


method !test ( Distribution::Locally:D :$dist! ) {

  <tests t>
    ==> map( -> $dir { $dist.prefix.add: $dir } )
    ==> grep( *.d )
    ==> map( -> $dir { Rakudo::Internals.DIR-RECURSE: ~$dir, file => *.ends-with: any <.rakutest .t> } )
    ==> flat( )
    ==> map( *.IO )
    ==> my @test;

  return unless @test;

  🦋 TST ~ "｢$dist｣";


  my $prefix  = $dist.prefix;

  %*ENV<RAKULIB> = "$*stage.path-spec()";

  my Int $exitcode;

  @test.race( :1batch, degree => $!cores ).map( -> $test {

    🦋 TST ~ "｢$test.basename()｣";


    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test.relative: $prefix;

      whenever $proc.stdout.lines { 🐛 TST ~ $^out }
      whenever $proc.stderr.lines { 🦗 TST ~ $^err }

      whenever $proc.stdout.stable( 42 ) {

      🦋 WAI ~ "｢$proc.command()｣";

      }


      whenever $proc.stdout.stable( 420 ) {

        🐞 TOT ~ "｢$dist｣";

        $proc.kill;

        $exitcode =  1;

        done;

      }


      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        $exitcode = 1 if .exitcode;

        done;

      }

    }

    last if $exitcode;

  });

  die X::Pakku::Test.new: :$dist if $exitcode;

  🐞 OLO ~ "｢$dist｣" if $exitcode;

  🧚 TST ~ "｢$dist｣";

}

method !build ( Distribution::Locally:D :$dist ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  🦋 BLD ~ "｢$dist｣";

  my @deps = $dist.deps( :deps ).grep( { .from ~~ 'raku' } );

  my $cmd = $builder

    ?? qq:to/CMD/

    @deps.map( -> $dep { "use $dep;" } ).join( "\n" )

    my %meta   := { $dist.meta.raku };

    ::( '$builder' ).new( :%meta ).build( '$prefix' );

    CMD

    !! qq:to/CMD/;

    @deps.map( -> $dep { "require ::( '$dep' );" } )

    require '$file';

    ::( 'Build' ).new.build(  '$prefix' );

    CMD

  my $proc = Proc::Async.new: ~$*EXECUTABLE, '-I', $*stage.path-spec, '-e', $cmd;

  my $exitcode;

  react {

    whenever $proc.stdout.lines { 🐛 BLD ~ $^out }
    whenever $proc.stderr.lines { 🦗 BLD ~ $^err }

    whenever $proc.stdout.stable( 42 ) {

    🦋 WAI ~ "｢$proc.command()｣";

    }

    whenever $proc.stdout.stable( 420 ) {

      🐞 TOT ~ "｢$dist｣";

      $proc.kill;

      $exitcode = 1;

      done;

    }

    whenever $proc.start( cwd => $prefix, :%*ENV ) {

      $exitcode = .exitcode;

      done;

    }
  }

  die X::Pakku::Build.new: :$dist if $exitcode;

  🐞 OLO ~ "｢$dist｣" if $exitcode;

  🧚 BLD ~ "｢$dist｣";
}


multi method satisfy ( :@spec! ) {

  🦋 SPC ~ "｢{@spec}｣";

  my $meta =
    @spec.map( -> $spec {

      my $meta = try samewith :$spec;

      if $meta {

        🦋 MTA ~ "｢$meta｣"; 

        return $meta;

      }

    } );

  die X::Pakku::Meta.new: meta => @spec unless $meta;;

}

multi method satisfy ( Pakku::Spec::Raku:D :$spec! ) {

  🐛 SPC ~ "｢$spec｣";

  my $meta = try Pakku::Meta.new(
    ( $spec.prefix                            ) //
    ( $!cache  .recommend: :$spec if $!cache  ) //
    ( $!recman .recommend: :$spec if $!recman )
  );

  die X::Pakku::Meta.new: meta => $spec unless $meta;

  if $meta {

    🦋 MTA ~ "｢$meta｣"; 

    $meta;
  }

}

multi method satisfy ( Pakku::Spec::Bin:D    :$spec! ) { die X::Pakku::Spec.new: :$spec; 🐞 OLO ~ "｢$spec｣"; Empty }
multi method satisfy ( Pakku::Spec::Native:D :$spec! ) { die X::Pakku::Spec.new: :$spec; 🐞 OLO ~ "｢$spec｣"; Empty }

multi method satisfied ( Pakku::Spec::Raku:D   :$spec! --> Bool:D ) { return so $*repo.candies( $spec ) }
multi method satisfied ( Pakku::Spec::Bin:D    :$spec! --> Bool:D ) { return False unless find-bin $spec.name; True }
multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  my \lib = $*VM.platform-library-name( $spec.name.IO, |( version => Version.new( $_ ) with $spec.ver ) ).Str;

  Pakku::Native.can-load: lib; 
 
}

multi method satisfied ( :@spec! --> Bool:D ) { so @spec.first( -> $spec { samewith :$spec } ) }


method get-deps ( Pakku::Meta:D $meta, :$deps, :$exclude ) {

  state %visited;
  
  once %visited{ .name } = True with $exclude;

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


method fetch ( Pakku::Meta:D :$meta! ) {

  🦋 FTC ~ "｢$meta｣";

  with $meta.meta<path> -> $path {

    🐛 FTC ~ "｢$path｣";

    return $path;

  }

  my $norm-name = norm-name ~$meta;

  my $dest = mkdir $!cached.add( $meta.name.subst: '::', '-', :g ).add( $norm-name );

  my $url      = $meta.source-url;
  my $download = $dest.add( $norm-name ~ '.tar.gz' ).Str;

  🐛 FTC ~ "｢$url｣";

  $!recman.fetch: :$url :$download;

  my $extract = extract archive => $download, dest => ~$dest;

  die X::Pakku::Archive.new: :$download unless $extract;

  # use recman META becuase some dists missing auth or ver in meta file
  $dest.add( 'META6.json' ).spurt: $meta.to-json;

  unlink $download;

  🐛 FTC ~ "｢$dest｣";

  $dest;

}


method fly ( ) {

  my $cmd = %!cnf<cmd>;

  self."$cmd"( |%!cnf{ $cmd } );


	CATCH {
		
		when X::Pakku { 🦗 .message; .resume if $!yolo; nofun; exit 1 }
		
		default { 🦗 .gist; nofun; exit 1 }

	}

}


submethod BUILD ( :%!cnf! ) {

  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $verbose = %!cnf<pakku><verbose> // 2;
  my %level   = %!cnf<log><level>     // {};
  my $cache   = %!cnf<pakku><cache>   // True;
  my $recman  = %!cnf<pakku><recman>  // True;
  my @url     = %!cnf<recman>.flat;

  $!cores = $*KERNEL.cpu-cores - 1;

  $!dont  = %!cnf<pakku><dont>    // False;
  $!yolo  = %!cnf<pakku><yolo>    // False;

  $!cached = $*HOME.add( '.pakku' ).add( 'cache' );
  $!stage  = $*HOME.add( '.pakku' ).add( 'stage' );

  $!cache  = Pakku::Cache.new:  :$!cached if $cache;
  $!recman = Pakku::Recman.new: :@url     if $recman;

  $!log    = Pakku::Log.new: :$pretty :$verbose :%level;

}


method new ( ) {

  CATCH {

    Pakku::Log.new: :pretty :2verbose;

    🦗 .message;
    
    nofun;
  }

  my $cmd = Grammar::Pakku::Cmd.parse( @*ARGS, actions => Grammar::Pakku::CmdActions );

  die X::Pakku::Cmd.new( cmd => @*ARGS ) unless $cmd;

  my %cmd = $cmd.made;

  my $user-config = $*HOME.add( '.pakku' ).add( 'pakku.cnf' );

  my $config-file = %cmd<pakku><config> // ( $user-config.e ?? $user-config !! %?RESOURCES<cnf/pakku.cnf> );

  my $cnf = Grammar::Pakku::Cnf.parsefile( $config-file.IO, actions => Grammar::Pakku::CnfActions.new );

  die X::Pakku::Cnf.new( cnf => $config-file ) unless $cnf;

  my %cnf =  hashmerge $cnf.made, %cmd;

  self.bless: :%cnf;

}

# Stolen from Hash::Merge:cpan:TYIL to fix #6
sub hashmerge ( %merge-into, %merge-source ) {

  for %merge-source.keys -> $key {
    if %merge-into{ $key } :exists {
      given %merge-source{ $key } {
        when Hash { hashmerge %merge-into{ $key }, %merge-source{ $key } }
        default { %merge-into{ $key } = %merge-source{ $key } }
      }
    }
    else { %merge-into{ $key } = %merge-source{ $key } }
  }

  %merge-into;
}

sub find-bin ( Str:D $name --> Bool:D ) is export {

  so $*SPEC.path.first( -> $path {
    $*SPEC.catfile( $path, $name ).IO.f or ( $*SPEC.catfile( $path, $name ~ '.exe'  ).IO.f if $*DISTRO.is-win )
  } )

}

sub norm-name ( Str:D $s ) is export { $s.trans: '< >:*' => '', / '::' / => '-', / [':ver' | ':auth' | ':api' ] / => '-' }
