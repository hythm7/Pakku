use X::Pakku;
use Pakku::Log;
use Pakku::Help;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Cache;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Pakku::Grammar::Cmd;

unit role Pakku::Core;
  also does Pakku::Help;

has      %!cnf;

has Bool $!dont;
has Bool $!yolo;

has Int  $!cores;
has Int  $!degree;

has IO::Path $!cached;
has IO::Path $!stage;

has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::Recman $!recman;

has CompUnit::Repository @!repo;

method !test ( Distribution::Locally:D :$dist!, Bool :$xtest ) {

	my @dir =  <tests t>;

	@dir.append: <xtest xt> if $xtest;

	@dir
    ==> map( -> $dir { $dist.prefix.add: $dir } )
    ==> grep( *.d )
    ==> map( -> $dir { Rakudo::Internals.DIR-RECURSE: ~$dir, file => *.ends-with: any <.rakutest .t> } )
    ==> flat( )
		==> sort( )
    ==> map( *.IO )
    ==> my @test;

  return unless @test;

  🦋 TST ~ "｢$dist｣";

  my $prefix  = $dist.prefix;

  %*ENV<RAKULIB> = "$*stage.path-spec()";

  my Int $exitcode;

  @test.hyper( :$!degree :1batch ).map( -> $test {

    🦋 TST ~ "｢$test.basename()｣";

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test.relative: $prefix;

      whenever $proc.stdout.lines { 🐛 TST ~ $^out }
      whenever $proc.stderr.lines { 🐞 TST ~ $^err }

      whenever $proc.stdout.stable( 42 ) { 🐞 WAI ~ "｢$proc.command()｣" }

      whenever $proc.stdout.stable( 420 ) {

        🐞 TOT ~ "｢$dist｣";

        $proc.kill;

        $exitcode =  1;

        🦗 TST ~ "｢$test.basename()｣";

        done;

      }

      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        if .exitcode { $exitcode = 1; 🦗 TST ~ "｢$test.basename()｣" }

        done;

      }

    }

    last if $exitcode;

  });

  if $exitcode {

		die X::Pakku::Test.new: :$dist;

		🐞 OLO ~ "｢$dist｣";

  }

  🧚 TST ~ "｢$dist｣";

}

method !build ( Distribution::Locally:D :$dist ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  🦋 BLD ~ "｢$dist｣";

  my @cmd; 

	if $builder {

    @cmd =
		  $*EXECUTABLE.absolute,
			'-I', $prefix,
			'-e', "require $builder; my %meta := { $dist.meta.raku }; ::( '$builder' ).new( :%meta ).build( '$prefix' );"
	} else {
    @cmd =
		  $*EXECUTABLE.absolute,
			'-e', "require '$file'; ::( 'Build' ).new.build( '$prefix' );"; # -I $prefix breaks Linenoise Build
	}

  %*ENV<RAKULIB> = "$*stage.path-spec()";

  my $proc = Proc::Async.new: @cmd;

  🐛 BLD ~ "｢$proc.command()｣";

  my $exitcode;

  react {

    whenever $proc.stdout.lines { 🐛 BLD ~ $^out }
    whenever $proc.stderr.lines { 🐞 BLD ~ $^err }

    whenever $proc.stdout.stable( 42 ) { 🐞 WAI ~ "｢$proc.command()｣" }

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

  if $exitcode { 

		die X::Pakku::Build.new: :$dist;

		🐞 OLO ~ "｢$dist｣";

  }

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
multi method satisfy ( Pakku::Spec::Perl:D   :$spec! ) { die X::Pakku::Spec.new: :$spec; 🐞 OLO ~ "｢$spec｣"; Empty }

multi method satisfied ( Pakku::Spec::Raku:D   :$spec! --> Bool:D ) { so flat @!repo.map( *.candidates: $spec.name, |$spec.spec ); }
multi method satisfied ( Pakku::Spec::Bin:D    :$spec! --> Bool:D ) { return False unless find-bin $spec.name; True }
multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  my \lib = $*VM.platform-library-name( $spec.name.IO, |( version => Version.new( $_ ) with $spec.ver ) ).Str;

  Pakku::Native.can-load: lib; 
 
}
multi method satisfied ( Pakku::Spec::Perl:D    :$spec! --> Bool:D ) { return False unless find-perl-module $spec.name; True }

multi method satisfied ( :@spec! --> Bool:D ) { so @spec.first( -> $spec { samewith :$spec } ) }


method upgradable ( Pakku::Spec::Raku:D :$spec! ) {

  my $inst = @!repo.map( *.candidates: $spec.name, |$spec.spec ).flat.map( *.meta ).sort( *.<ver> ).sort( *.<api> ).tail;

  die X::Pakku::Upgrade.new: :$spec unless $inst;

  my $inst-spec = Pakku::Spec.new: %( name => $spec.name, |$inst );

  🦋 UPG ~ "｢$inst-spec｣"; 

  my %candy-spec = %( name => $spec.name, auth => $spec.auth );

  my $candy-meta = $!recman.recommend: spec => Pakku::Spec.new: %candy-spec;

  die X::Pakku::Meta.new: spec => %candy-spec unless $candy-meta;

  my $candy-spec = Pakku::Spec.new: Pakku::Meta.new( Rakudo::Internals::JSON.from-json( $candy-meta )).Str;

  return Empty unless $candy-spec cmp $inst-spec ~~ More ;

  🦋 UPG ~ "｢$candy-spec｣"; 

  $candy-spec;

}

method get-deps ( Pakku::Meta:D $meta, :$deps, :@exclude ) {

	# cannot use .name instead of .id (that will save a few calls)
	# because dists that depends on two different versions of
	# same dependency, will fail. 
  state %visited;
  
  once for @exclude { %visited{ .id } = True } if @exclude;

  $meta.deps: :$deps

    ==> grep( -> $spec { not ( %visited{ $spec.?id // any @$spec.map( *.id ) } or self.satisfied( :$spec ) or not $spec.name )   } )

    ==> map(  -> $spec { self.satisfy: :$spec } )

    ==> my @meta-deps;

  return Empty unless +@meta-deps;

  my @dep;

  for @meta-deps -> $dep {

    my $id = $dep.id;

    next if %visited{ $id };

    %visited{ $id } = True;

    @dep.append: flat self.get-deps( $dep, :$deps), $dep
  }

  @dep;
}


method fetch ( Pakku::Meta:D :$meta! ) {

  🦋 FTC ~ "｢$meta｣";

  with $meta.meta<local-path> -> $local-path {

    🐛 FTC ~ "｢$local-path｣";

    return $local-path;

  }

  my $id = $meta.id;

  my $dest = mkdir $!cached.add( $meta.name.subst: '::', '-', :g ).add( $id );

  my $url      = $meta.source-url;
  my $download = $dest.add( $id ~ '.tar.gz' ).Str;

  🐛 FTC ~ "｢$url｣";

  $!recman.fetch: :$url :$download;

  my $extract = extract archive => $download, dest => ~$dest;

  die X::Pakku::Archive.new: :$download unless $extract;

  unlink $download;

  🐛 FTC ~ "｢$dest｣";

  $dest;

}

method clear-stage ( ) { clear-stage $!stage if $!stage.d }

method fly ( ) {

  END try self.clear-stage;

	CATCH {
		when X::Pakku { 🦗 .message; .resume if $!yolo; nofun; exit 1 }
		default       { 🦗 .gist;                       nofun; exit 1 }
	}

  my $cmd = %!cnf<cmd>;

  self."$cmd"( |%!cnf{ $cmd } );

}

submethod BUILD ( :%!cnf! ) {

  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $verbose = %!cnf<pakku><verbose> // 'now';
  my %level   = %!cnf<log><level>     // {};
  my $cache   = %!cnf<pakku><cache>   // True;
  my $recman  = %!cnf<pakku><recman>  // True;
  my @url     = %!cnf<recman>.flat;

  $!dont  = %!cnf<pakku><dont>    // False;
  $!yolo  = %!cnf<pakku><yolo>    // False;

  $!cores  = $*KERNEL.cpu-cores - 1;
  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  $!cached = $*HOME.add( '.pakku' ).add( 'cache' );

  $!stage  = $*HOME.add( '.pakku' ).add( 'stage' ).add( now.Num );

  $!cache  = Pakku::Cache.new:  :$!cached if $cache;
  $!recman = Pakku::Recman.new: :@url     if $recman;

  $!log    = Pakku::Log.new: :$pretty :$verbose :%level;

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );
}


method new ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd { 🦗 .message; nofun; }
      when X::Pakku::Cnf { 🦗 .message; nofun; }
      when JSONException { 🦗 .message; .resume; }
			default { 🦗 .gist }
  }

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::CmdActions );

  die X::Pakku::Cmd.new( cmd => @*ARGS ) unless $cmd;

  my %cnf = $cmd.made;

	%cnf<pakku><config> //= $*HOME.add( '.pakku' ).add( 'config.json' );

	my $config-file = %cnf<pakku><config>;

  if $config-file.e {

    my $cnf = Rakudo::Internals::JSON.from-json: slurp $config-file.IO;

    die X::Pakku::Cnf.new( cnf => $config-file ) unless $cnf;

    %cnf =  hashmerge $cnf, %cnf;

	}




  self.bless: :%cnf;

}

# borrowed from Hash::Merge:cpan:TYIL to fix #6
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

sub find-perl-module ( Str:D $name --> Bool:D ) {

  return True if run('perl', "-M$name", '-e 1', :err).exitcode == 0;

	return False;
}

sub clear-stage(IO::Path:D $io --> Nil) {
  # borrowed from CURS.self-destruct
  .d ?? clear-stage($_) !! .unlink for $io.dir;
  $io.rmdir;
}
