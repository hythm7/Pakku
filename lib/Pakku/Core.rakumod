use X::Pakku;
use Pakku::Log;
use Pakku::Help;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Cache;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Pakku::Config;
use Pakku::Grammar::Cmd;

unit role Pakku::Core;
  also does Pakku::Help;

has      %!cnf;

has Int  $!cores;
has Int  $!degree;
has Bool $!dont;
has Bool $!yolo;

has IO::Path $!stage;

has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::HTTP   $!http;
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

  my $archive = $dst.add( $dst.basename ~ '.tar.gz' );

  url-encode $src;

  $!http.download: url-encode( $src ), $archive;

  my $extract = extract :$archive, :$dst;

  die X::Pakku::Archive.new: :$archive unless $extract;

  unlink $archive;

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

  my $home = %!cnf<pakku><home>;

  my $pretty   = %!cnf<pakku><pretty>  // True;
  my $verbose  = %!cnf<pakku><verbose> // 'now';
  my %level    = %!cnf<log><level>     // {};

  $!log    = Pakku::Log.new: :$pretty :$verbose :%level;
  
  🐛 qq[CNF: ‹home› $home];

  $!tmp = $home.add( '.tmp' );

  🐛 qq[CNF: ‹tmp› $!tmp];

  $!stage  = $home.add( '.stage' );

  🐛 qq[CNF: ‹stage› $!stage];

  my $cache-conf = %!cnf<pakku><cache>; 
  my $cache      = $home.add( '.cache' ); 

  if $cache-conf {
    $cache = $cache-conf unless $cache-conf === True;  
  }

  $!cache = Pakku::Cache.new:  :$cache if $cache;

  🐛 qq[CNF: ‹cache› $cache];

  $!dont  = %!cnf<pakku><dont> // False;

  🐛 qq[CNF: ‹dont› $!dont];

  $!yolo  = %!cnf<pakku><yolo> // False;

  🐛 qq[CNF: ‹yolo› $!yolo];

  $!cores  = $*KERNEL.cpu-cores - 1;

  🐛 qq[CNF: ‹cores› $!cores];

  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  🐛 qq[CNF: ‹degree› $!degree];

  my $recman   = %!cnf<pakku><recman>;
  my $norecman = %!cnf<pakku><norecman>;

  my @recman = %!cnf<recman> ?? %!cnf<recman>.flat !! ( %( :name<pakku>, :location<http://recman.pakku.org>, :1priority, :active ), );

  @recman .= grep: { .<name> !~~ $norecman } if $norecman;
  @recman .= grep: { .<name>  ~~ $recman   } if $recman;

  $!http  = Pakku::HTTP.new;

  $!recman = Pakku::Recman.new: :$!http :@recman if @recman;

  @recman.map( -> $recman { 🐛 qq[CNF: ‹recman› $recman<location>] } );

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );

  🐛 qq[CNF: ‹repos› {@!repo}];

}


method metamorph ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd { 🦗 .message; nofun   }
      when X::Pakku::Cnf { 🦗 .message; nofun   }
      when JSONException { 🦗 .message; .resume }

      default { 🦗 .gist }
  }

  my $home = $*HOME.add( '.pakku' );

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::CmdActions );

  die X::Pakku::Cmd.new( cmd => @*ARGS ) unless $cmd;

  my %cmd = $cmd.made;

  my %env = get-env;

  my %cnf = hashmerge %env, %cmd;


  if %cnf<pakku><config>:exists {

    die X::Pakku::Cnf.new( cnf => %cnf<pakku><config> ) unless %cnf<pakku><config>.IO.f;

  }

  %cnf<pakku><config> //= $home.add( 'config.json' );

  my $config-file = %cnf<pakku><config>.IO;

  if $config-file.f {

    my $cnf = Rakudo::Internals::JSON.from-json: slurp $config-file.IO;

    die X::Pakku::Cnf.new( cnf => $config-file ) unless defined $cnf;

    %cnf =  hashmerge $cnf, %cnf;

  }

  %cnf<pakku><home> = $home;

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

sub url-encode ( Str() $text --> Str ) {
  return $text.subst:
    /<-[
      ! * ' ( ) ; : @ + $ , / ? # \[ \]
      0..9 A..Z a..z \- . ~ _
    ]> /,
      { .Str.encode».fmt('%%%02X').join }, :g;
}

sub get-env ( ) {

  my %env;

  %env<pakku><cache>    = %*ENV<PAKKU_CACHE>       if %*ENV<PAKKU_CACHE>;
  %env<pakku><verbose>  = %*ENV<PAKKU_VERBOSE>     if %*ENV<PAKKU_VERBOSE>;
  %env<pakku><recman>   = %*ENV<PAKKU_RECMAN>      if %*ENV<PAKKU_RECMAN>;
  %env<pakku><norecman> = %*ENV<PAKKU_NORECMAN>    if %*ENV<PAKKU_NORECMAN>;
  %env<pakku><config >  = %*ENV<PAKKU_CONFIG>.IO   if %*ENV<PAKKU_CONFIG>;
  %env<pakku><dont>     = %*ENV<PAKKU_DONT>.Bool   if %*ENV<PAKKU_DONT>;
  %env<pakku><yoloy>    = %*ENV<PAKKU_YOLO>.Bool   if %*ENV<PAKKU_YOLO>;
  %env<pakku><pretty>   = %*ENV<PAKKU_PRETTY>.Bool if %*ENV<PAKKU_PRETTY>;

  %env<pakku><add><to>         = %*ENV<PAKKU_ADD_TO>                       if %*ENV<PAKKU_ADD_TO>;
  %env<pakku><add><deps>       = %*ENV<PAKKU_ADD_DEPS>                     if %*ENV<PAKKU_ADD_DEPS>;
  %env<pakku><add><test>       = %*ENV<PAKKU_ADD_TEST>.Bool                if %*ENV<PAKKU_ADD_TEST>;
  %env<pakku><add><build>      = %*ENV<PAKKU_ADD_BUILD>.Bool               if %*ENV<PAKKU_ADD_BUILD>;
  %env<pakku><add><force>      = %*ENV<PAKKU_ADD_FORCE>.Bool               if %*ENV<PAKKU_ADD_FORCE>;
  %env<pakku><add><xtest>      = %*ENV<PAKKU_ADD_XTEST>.Bool               if %*ENV<PAKKU_ADD_XTEST>;
  %env<pakku><add><precompile> = %*ENV<PAKKU_ADD_PRECOMPILE>.Bool          if %*ENV<PAKKU_ADD_PRECOMPILE>;
  %env<pakku><add><exclude>    = %*ENV<PAKKU_ADD_EXCLUDE>.split( / \s+ / ) if %*ENV<PAKKU_ADD_EXCLUDE>;

  %env<pakku><test><build> = %*ENV<PAKKU_TEST_BUILD>.Bool if %*ENV<PAKKU_TEST_BUILD>;
  %env<pakku><test><xtest> = %*ENV<PAKKU_TEST_XTEST>.Bool if %*ENV<PAKKU_TEST_XTEST>;

  %env<pakku><remove><from> = %*ENV<PAKKU_REMOVE_FROM> if %*ENV<PAKKU_REMOVE_FROM>;

  %env<pakku><list><repo>    = %*ENV<PAKKU_LIST_REPO>         if %*ENV<PAKKU_LIST_REPO>;
  %env<pakku><list><details> = %*ENV<PAKKU_LIST_DETAILS>.Bool if %*ENV<PAKKU_LIST_DETAILS>;

  %env<pakku><search><count>   = %*ENV<PAKKU_SEARCH_count>.Int    if %*ENV<PAKKU_SEARCH_COUNT>;
  %env<pakku><search><details> = %*ENV<PAKKU_SEARCH_DETAILS>.Bool if %*ENV<PAKKU_SEARCH_DETAILS>;
  %env<pakku><search><relaxed> = %*ENV<PAKKU_SEARCH_RELAXED>.Bool if %*ENV<PAKKU_SEARCH_RELAXED>;

  %env<pakku><update><in>         = %*ENV<PAKKU_UPDATE_IN>                       if %*ENV<PAKKU_UPDATE_IN>;
  %env<pakku><update><deps>       = %*ENV<PAKKU_UPDATE_DEPS>                     if %*ENV<PAKKU_UPDATE_DEPS>;
  %env<pakku><update><test>       = %*ENV<PAKKU_UPDATE_TEST>.Bool                if %*ENV<PAKKU_UPDATE_TEST>;
  %env<pakku><update><xtest>      = %*ENV<PAKKU_UPDATE_XTEST>.Bool               if %*ENV<PAKKU_UPDATE_XTEST>;
  %env<pakku><update><build>      = %*ENV<PAKKU_UPDATE_BUILD>.Bool               if %*ENV<PAKKU_UPDATE_BUILD>;
  %env<pakku><update><force>      = %*ENV<PAKKU_UPDATE_FORCE>.Bool               if %*ENV<PAKKU_UPDATE_FORCE>;
  %env<pakku><update><clean>      = %*ENV<PAKKU_UPDATE_CLEAN>.Bool               if %*ENV<PAKKU_UPDATE_CLEAN>;
  %env<pakku><update><precompile> = %*ENV<PAKKU_UPDATE_PRECOMPILE>.Bool          if %*ENV<PAKKU_UPDATE_PRECOMPILE>;
  %env<pakku><update><exclude>    = %*ENV<PAKKU_UPDATE_EXCLUDE>.split( / \s+ / ) if %*ENV<PAKKU_UPDATE_EXCLUDE>;


  %env<pakku><state><clean>   = %*ENV<PAKKU_STATE_CLEAN>.Bool   if %*ENV<PAKKU_STATE_CLEAN>;
  %env<pakku><state><updates> = %*ENV<PAKKU_STATE_UPDATES>.Bool if %*ENV<PAKKU_STATE_UPDATES>;

 %env;

}
