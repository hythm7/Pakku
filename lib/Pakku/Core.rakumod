use X::Pakku;
use Pakku::Log;
use Pakku::Help;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Curl;
use Pakku::Cache;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Pakku::Config;
use Pakku::Grammar::Cmd;

unit role Pakku::Core;
  also does Pakku::Help;

has      %!cnf;

has Bool $!dont;
has Bool $!yolo;

has Int  $!cores;
has Int  $!degree;

has IO::Path $!stage;

has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::Curl   $!curl;
has Pakku::Recman $!recman;

has CompUnit::Repository @!repo;

has IO::Path $!tmp;

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

  🦋 qq[TST: ｢$dist｣];

  my $prefix  = $dist.prefix;

  %*ENV<RAKULIB> = "$*stage.path-spec()";

  my Int $exitcode;

  @test.hyper( :$!degree :1batch ).map( -> $test {

    🦋 qq[TST: ｢$test.basename()｣];

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test.relative: $prefix;

      whenever $proc.stdout.lines { 🐛 "TST: " ~ $^out }
      whenever $proc.stderr.lines { 🐞 "TST: " ~ $^err }

      whenever $proc.stdout.stable( 42 ) { 🐞 "WAI: " ~ "｢$proc.command()｣" }

      whenever $proc.stdout.stable( 420 ) {

        🐞 qq[TOT: ｢$dist｣];

        $proc.kill;

        $exitcode =  1;

        🦗 qq[TST: ｢$test.basename()｣];

        done;

      }

      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        if .exitcode { $exitcode = 1; 🦗 "TST: " ~ "｢$test.basename()｣" }

        done;

      }

    }

    last if $exitcode;

  });

  if $exitcode {

    die X::Pakku::Test.new: :$dist;

    🐞 qq[OLO: ｢$dist｣];

  }

  🧚 qq[TST: ｢$dist｣];

}

method !build ( Distribution::Locally:D :$dist ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  🦋 qq[BLD: ｢$dist｣];

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

  🐛 qq[BLD: ｢$proc.command()｣];

  my $exitcode;

  react {

    whenever $proc.stdout.lines { 🐛 "BLD: " ~ $^out }
    whenever $proc.stderr.lines { 🐞 "BLD: " ~ $^err }

    whenever $proc.stdout.stable( 42 ) { 🐞 "WAI: " ~ "｢$proc.command()｣" }

    whenever $proc.stdout.stable( 420 ) {

      🐞 qq[TOT: ｢$dist｣];

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

    🐞 qq[OLO: ｢$dist｣];

  }

  🧚 qq[BLD: ｢$dist｣];

}

multi method satisfy ( Pakku::Spec::Raku:D :$spec! ) {

  🐛 qq[SPC: ｢$spec｣ satisfying!];

  my $meta = try Pakku::Meta.new(
    ( $!cache.recommend( :$spec ).meta if $!cache  ) //
    ( $!recman.recommend: :$spec       if $!recman )
  );

  unless $meta {

    🐞 qq[SPC: ｢$spec｣ could not satisfy!];

    die X::Pakku::Spec.new: :$spec;

    🐞 qq[OLO: ｢$spec｣"];
  }

  🦋 qq[MTA: ｢$meta｣];

  $meta;

}

multi method satisfy ( Pakku::Spec::Bin:D    :$spec! ) {

  🐞 qq[SPC: ｢$spec｣ could not satisfy!];

  die X::Pakku::Spec.new: :$spec;

  🐞 qq[OLO: ｢$spec｣"];

  Empty;

}
multi method satisfy ( Pakku::Spec::Native:D :$spec! ) {

  🐞 qq[SPC: ｢$spec｣ could not satisfy!];

  die X::Pakku::Spec.new: :$spec;

  🐞 qq[OLO: ｢$spec｣"];

  Empty

}

multi method satisfy ( Pakku::Spec::Perl:D :$spec! ) {

  🐞 qq[SPC: ｢$spec｣ could not satisfy!];

  die X::Pakku::Spec.new: :$spec;

  🐞 qq[OLO: ｢$spec｣"];

  Empty
}

multi method satisfy ( :@spec! ) {

  🐛 qq[SPC: ｢{@spec}｣ satisfying!];

  my $meta =
    @spec.map( -> $spec {

      🐛 qq[SPC: ｢$spec｣ trying!];

      my $meta = try samewith :$spec;

      return $meta if $meta;

    } );

  die X::Pakku::Spec.new: :@spec unless $meta;;

  🐞 qq[OLO: ｢{@spec}｣"];

  Empty
}


multi method satisfied ( Pakku::Spec::Raku:D   :$spec! --> Bool:D ) {

  my $name = $spec.name;
  my %spec = $spec.spec;

  # File::Which has empty dep name
  # should be removed after File::Which is fixed
  return True if $name eq '';

  return False unless @!repo.first( *.candidates: $name, |%spec );

  🐛 qq[SPC: ｢$spec｣ already satisfied!];

  True;
}

multi method satisfied ( Pakku::Spec::Bin:D    :$spec! --> Bool:D ) {

  return False unless find-bin $spec.name;

  🐛 qq[SPC: ｢$spec｣ already satisfied!];

  True;
}

multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  my \lib = $*VM.platform-library-name( $spec.name.IO, |( version => Version.new( $_ ) with $spec.ver ) ).Str;

  return False unless Pakku::Native.can-load: lib; 
 
  🐛 qq[SPC: ｢$spec｣ already satisfied!];

  True;
}
multi method satisfied ( Pakku::Spec::Perl:D    :$spec! --> Bool:D ) {

  return False unless find-perl-module $spec.name;
 
  🐛 qq[SPC: ｢$spec｣ already satisfied!];

  True;
}

multi method satisfied ( :@spec! --> Bool:D ) { so @spec.first( -> $spec { samewith :$spec } ) }

method get-deps ( Pakku::Meta:D $meta, :$deps = True, :@exclude ) {

  state %visited;

  once for @exclude { %visited{ .id } = True } if @exclude;

  $meta.deps( :$deps )
    ==> grep( -> $spec { 
      not ( 
            %visited{ $spec.?id // @$spec.map( *.id ).any }:exists or
            self.satisfied( :$spec )
          )
      } )
    ==> map(  -> $spec {

    my $meta = self.satisfy: :$spec;

    %visited{ $spec.id } = True;

    self.get-deps( $meta, :$deps), $meta;

  } )

}


# TODO: subset TarGzURL of Str
multi method fetch ( Str:D :$src!, IO::Path:D :$dst! ) {

  🐛 qq[FTC: ｢$src｣];

  mkdir $dst;

  my $download = $dst.add( $dst.basename ~ '.tar.gz' ).Str;

  retry { $!curl.download: :URL( $src ), :$download };

  my $extract = extract archive => $download, dest => ~$dst;

  die X::Pakku::Archive.new: :$download unless $extract;

  unlink $download;

  🐛 qq[FTC: ｢$dst｣];

}

multi method fetch ( IO::Path:D :$src!, IO::Path:D :$dst! ) {

  copy-dir :$src :$dst;

}


method clear ( ) {

  try remove-dir $!tmp   if $!tmp.d;
  try remove-dir $!stage if $!stage.d;

}

method cnf ( ) { %!cnf }

submethod BUILD ( :%!cnf! ) {

  my $pakku-dir = $*HOME.add( '.pakku' );

  my $pretty   = %!cnf<pakku><pretty>  // True;
  my $verbose  = %!cnf<pakku><verbose> // 'now';
  my %level    = %!cnf<log><level>     // {};

  
  $!tmp = $pakku-dir.add( '.tmp' );

  $!log    = Pakku::Log.new: :$pretty :$verbose :%level;

  $!dont  = %!cnf<pakku><dont> // False;
  $!yolo  = %!cnf<pakku><yolo> // False;

  $!cores  = $*KERNEL.cpu-cores - 1;
  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  $!stage  = $pakku-dir.add( '.stage' );

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );


  my $cache-conf = %!cnf<pakku><cache>; 
  my $cache      = $pakku-dir.add( '.cache' ); 

  with $cache-conf {
    $cache = $cache-conf unless $cache-conf === True;  
  }

  $!cache = Pakku::Cache.new:  :$cache if $cache;

  my $recman   = %!cnf<pakku><recman>;
  my $norecman = %!cnf<pakku><norecman>;

  my @recman = %!cnf<recman> ?? %!cnf<recman>.flat !! ( %( :name<pakku>, :location<http://recman.pakku.org>, :1priority, :active ), );

  @recman .= grep: { .<name> !~~ $norecman } if $norecman;
  @recman .= grep: { .<name>  ~~ $recman   } if $recman;

  $!curl  = Pakku::Curl.new;

  $!recman = Pakku::Recman.new: :$!curl :@recman if @recman;

}


method metamorph ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd { 🦗 .message; nofun   }
      when X::Pakku::Cnf { 🦗 .message; nofun   }
      when JSONException { 🦗 .message; .resume }

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

  self.bless( :%cnf );

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

sub repo-from-spec ( Str $spec ) is export {

  return CompUnit::RepositoryRegistry.repository-for-name( $spec ) if $spec ~~ any <home site vendor core>;

  return CompUnit::Repository unless $spec;

  my $repo-spec = CompUnit::Repository::Spec.from-string( $spec, 'inst' );
  my $name = $repo-spec.options<name> // 'custom-lib';

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec( $repo-spec );

  CompUnit::RepositoryRegistry.register-name( $name, $repo );

  $repo;
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

sub copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst! --> Nil) is export {

  my $relpath := $src.chars;

  for Rakudo::Internals.DIR-RECURSE( ~$src ) -> $path {

    my $destination := $dst.add( $path.substr( $relpath ) );

    $destination.parent.mkdir;

    $path.IO.copy: $destination;

  }
}

sub remove-dir( IO::Path:D $io --> Nil ) is export {
  .d ?? remove-dir( $_ ) !! .unlink for $io.dir;
  $io.rmdir;
}

