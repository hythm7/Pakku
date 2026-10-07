use CompUnit::Repository::Staging;

use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Cache;
use Pakku::Util;
use Pakku::Fetch;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Pakku::Grammar::Cmd;

unit role Pakku::Core;

has %!cnf;

has IO::Path $!home;
has IO::Path $!stage;
has IO::Path $!tmp;

has Int  $!cores;
has Int  $!degree;
has Bool $!dont;
has Bool $!force;
has Bool $!yolo;


has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::Fetch  $!fetch;
has Pakku::Recman $!recman;

has CompUnit::Repository @!repo;


method !home   { $!home   }
method !tmp    { $!tmp    }
method !degree { $!degree }
method !dont   { $!dont   }
method !force  { $!force  }
method !yolo   { $!yolo   }
method !stage  { $!stage  }
method !cache  { $!cache  }
method !fetch  { $!fetch  }
method !recman { $!recman }
method !repo   { @!repo   }

method test (
  CompUnit::Repository::Staging:D :$stage!,
  Distribution::Locally:D :$dist!,
  Bool :$xtest
  ) {

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

  my $prefix  = $dist.prefix;

  %*ENV<RAKULIB> = "$stage.path-spec( )";

  my Int $exitcode;

  my $processed = 0;
  my $total     = +@test;

  bar.header: 'TST';
  bar.length: $dist.Str.chars;
  bar.sym: $dist.Str;

  bar.activate;

  @test.hyper( :$!degree :1batch ).map( -> $test {


    log '🦋', header => 'TST', msg => $test.basename;

    react {

      my $proc = Proc::Async.new: $*EXECUTABLE, $test.relative: $prefix;
      whenever $proc.stdout.lines { log '🐝',  :header<TST> :msg( $^out ), :!msg-delimit }
      whenever $proc.stderr.lines { log '🐞', :header<TST> :msg( $^err ), :!msg-delimit}

      whenever $proc.stdout.stable( 42 ) { log '🐞', header => 'WAI', msg =>  ~$proc.command }

      whenever $proc.stdout.stable( 420 ) {

        log '🐞', header => 'TOT', msg => ~$dist;

        $proc.kill;

        $exitcode =  1;

        log '🦗', header => 'TST', msg => $test.basename;

        done;

      }

      whenever $proc.start( cwd => $prefix, :%*ENV ) {

        my $percent = $processed / $total * 100;

        $processed += 1;

        bar.percent: $percent;

        bar.show;

        if .exitcode { $exitcode = 1; log '🦗', header => 'TST', msg => $test.basename }

        done;

      }

    }


    last if $exitcode;

  } );
    
  bar.deactivate;

  if $exitcode {

    die X::Pakku::Test.new: msg => ~$dist;

    log '🐞', header => 'OLO', msg => ~$dist;

  } else {

    log '🧚', header => 'TST', msg => ~$dist;

  }

}

method build (

  CompUnit::Repository::Staging:D :$stage!,
  Distribution::Locally:D :$dist!
  ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  log '🦋', header => 'BLD', msg => ~$dist;

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

  %*ENV<RAKULIB> = "$stage.path-spec()";

  my $proc = Proc::Async.new: @cmd;

  log '🐛', header => 'BLD', msg => ~$proc.command;

  my $exitcode;

  react {

      whenever $proc.stdout.lines { log '🐝',  :header<BLD> :msg( $^out ), :!msg-delimit }
      whenever $proc.stderr.lines { log '🐞', :header<BLD> :msg( $^err ), :!msg-delimit}

      whenever $proc.stdout.stable( 42 ) { log '🐞', header => 'WAI', msg =>  ~$proc.command }

    whenever $proc.stdout.stable( 420 ) {

      log '🐞', header => 'TOT', msg => ~$dist;

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

    die X::Pakku::Build.new: msg => ~$dist;

    log '🐞', header => 'OLO', msg => ~$dist;

  } else {

    log '🧚', header => 'BLD', msg => ~$dist;

  }

}

multi method satisfy ( Pakku::Spec::Raku:D :$spec! ) {

  # File::Which has empty dep name
  # should be removed after File::Which is fixed
  next unless $spec.name;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfying!';

  # the index is local and newest-first; the cache only answers when it can not (norecman, offline)
  my $meta = try Pakku::Meta.new(
    ( $!recman.recommend( :$spec )      if $!recman ) //
    ( $!cache.recommend( :$spec ).?meta if $!cache  )
  );

  unless $meta {

    log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

    die X::Pakku::Spec.new: msg => ~$spec;

    log '🐞', header => 'OLO', msg => ~$spec;
  }

  log '🧚', header => 'MTA', msg => ~$meta;

  $meta;

}

multi method satisfy ( Pakku::Spec::Bin:D    :$spec! ) {

  log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

  die X::Pakku::Spec.new: msg => ~$spec;

  log '🐞', header => 'OLO', msg => ~$spec;

  Empty;

}
multi method satisfy ( Pakku::Spec::Native:D :$spec! ) {

  log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

  die X::Pakku::Spec.new: msg => ~$spec;

  log '🐞', header => 'OLO', msg => ~$spec;

  Empty

}

multi method satisfy ( Pakku::Spec::Perl:D :$spec! ) {

  log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

  die X::Pakku::Spec.new: msg => ~$spec;

  log '🐞', header => 'OLO', msg => ~$spec;

  Empty
}

multi method satisfy ( Pakku::Spec::Any:D :$spec! ) {

  my @spec = $spec.spec;

  log '🐛', header => 'SPC', msg => ~@spec, comment => 'satisfying!';

  my $meta =
    @spec.map( -> $spec {

      log '🐛', header => 'SPC', msg => ~$spec, comment => 'trying!';

      my $meta = try samewith :$spec;

      return $meta if $meta;

    } );

  die X::Pakku::Spec.new: msg => ~@spec unless $meta;;

  log '🐞', header => 'OLO', msg => ~@spec;

  Empty
}


multi method satisfied ( Pakku::Spec::Raku:D   :$spec! --> Bool:D ) {

  return False unless @!repo.first( *.candidates( $spec.dependency-specification ) );

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Bin:D    :$spec! --> Bool:D ) {

  return False unless find-bin $spec.name;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  my \lib = $*VM.platform-library-name( $spec.name.IO, |( version => Version.new( $_ ) with $spec.ver ) ).Str;

  return False unless Pakku::Native.can-load: lib; 
 
  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Perl:D    :$spec! --> Bool:D ) {

  return False unless find-perl-module $spec.name;
 
  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Any:D :$spec! --> Bool:D ) { so $spec.spec.first( -> $spec { samewith :$spec } ) }

method get-deps ( Pakku::Meta:D $meta, :$deps = True, Bool:D :$contained = False, :@exclude ) {

  state %visited = @exclude.map: *.id => True;

  $meta.deps( :$deps )
    ==> grep( -> $spec { %visited{ $spec.id }:!exists } )
    ==> grep( -> $spec { $contained and $spec ~~ Pakku::Spec::Raku or not self.satisfied( :$spec ) } )
    ==> map(  -> $spec {

    my $meta = self.satisfy: :$spec;

    %visited{ $spec.id } = True;

    self.get-deps( $meta, :$deps, :$contained ), $meta if $meta;

  } )

}


multi method fetch ( Str:D :$src!, IO::Path:D :$dst! ) {

  log '🐛', header => 'FTC', msg => ~$src;

  log '🐝', header => 'FTC', msg => ~$src, comment => ~$dst;

  mkdir $dst;

  my $archive = $dst.add( $dst.basename ~ '.tar.gz' );

  # index sources are already valid URLs (REA's are even pre-encoded): never re-encode them
  retry { $!fetch.download: url => $src, dst => $archive, progress => $!degree == 1 };

  log '🐛', header => 'EXT', msg => ~$archive;

  {
    # a rejected or corrupt archive must not leave a half-extracted dist behind
    CATCH { when X::Pakku::Archive { try remove-dir $dst; .rethrow } }

    extract :$archive, :$dst;
  }

  log '🐛', header => 'RMV', msg => ~$archive;

  unlink $archive;

  log '🐛', header => 'FTC', msg => ~$dst;

}

multi method fetch ( IO::Path:D :$src!, IO::Path:D :$dst! ) {

  log '🐛', header => 'FTC', msg => ~$src;

  log '🐝', header => 'FTC', msg => ~$src, comment => $dst;

  copy-dir :$src :$dst;

  log '🐛', header => 'FTC', msg => ~$dst;

}

method state ( :$updates = True ) {

  my %state;

  @!repo
    ==> map( *.installed )
    ==> grep( *.defined )
    ==> flat(  )
    ==> map( { Pakku::Meta.new: .meta } )
    ==> my @meta;

    spinner.header: 'STT';
    spinner.frames: @meta.map( *.Str );
    spinner.activate;

    @meta.map( -> $meta { 

      log '🐛', header => 'STT', msg => ~$meta;

      unless %state{ $meta }:exists {

        %state{ $meta }.<dep> = [];
        %state{ $meta }.<rev> = [];
        %state{ $meta }.<upd> = [];

      }

      %state{ $meta }.<meta> = $meta;

      my @upd;

      if $updates and $!recman {

        my $spec  = Pakku::Spec.new: $meta.name ~ ( ":auth<{ $meta.auth }>" if $meta.auth );
        my $found = $!recman.recommend: :$spec;

        with $found {
          my $newer = Pakku::Meta.new: $found;
          @upd.push: $newer if latest-first( $found, $meta ) ~~ Less and not self.satisfied( spec => Pakku::Spec.new: ~$newer );
        }

      }

      if @upd {
        %state{ $meta  }.<upd> .append: @upd;
      }

      sink $meta.deps( :deps ).grep( Pakku::Spec::Raku ).grep( *.name.so ).map( -> $spec {

        log '🐛', header => 'SPC', msg => ~$spec;

        @!repo
          ==> map( -> $repo { $repo.candidates( $spec.dependency-specification ).head } )
          ==> grep( *.defined )
          ==> my @candy;

        my $candy = @candy.head;

        unless $candy {

          log '🐛', header => 'SPC', msg => ~$spec, comment => 'missing!';

          %state{ $meta }.<dep> .push: $spec;

          next;
        }

        my $dep = Pakku::Meta.new: $candy.read-dist( )( $candy.id );

        log '🐛', header => 'DEP', msg => ~$dep;

        %state{ $meta }.<dep> .push: $dep;
        %state{ $dep  }.<rev> .push: $meta;

      } );

      spinner.next;

  } );

  spinner.deactivate;

  my %meta;

  %state.values
    ==> map( *.<meta> )
    ==> map( -> $meta { %meta{ $meta.name }.push: $meta } );

  %state.values
    ==> grep( *.<rev>.not )
    ==> map( *.<meta> )
    ==> grep( -> $meta {
       any %meta{ $meta.name }.map( {
         ( quietly Version.new( $meta.meta.<version> ) cmp Version.new( .meta<version> ) or  
           quietly Version.new( $meta.meta.<api>     ) cmp Version.new( .meta<api>     )  
         ) ~~ Less
       } ) 
    } )
    ==> map( -> $meta { %state{ $meta }<cln> = True } );

  %state;
}

method repo-from-spec ( Str :$spec ) { repo-from-spec $spec }

method copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst! --> Nil ) {
  copy-dir :$src, :$dst;
}

method clear ( ) {

  try remove-dir $!tmp   if $!tmp.d;
  try remove-dir $!stage if $!stage.d;

}

method !cnf ( ) { %!cnf }

submethod BUILD ( :%!cnf! ) {

  $!home = %!cnf<pakku><home>;

  my $pretty   = %!cnf<pakku><pretty>  // True;
  my $bar      = %!cnf<pakku><bar>     // True;
  my $spinner  = %!cnf<pakku><spinner> // True;
  my $cores    = %!cnf<pakku><cores>   //  $*KERNEL.cpu-cores;;
  my $verbose  = %!cnf<pakku><verbose> // 'info';
  my %level    = %!cnf<log>            // {};

  $!log    = Pakku::Log.new: :$pretty :$bar :$spinner :$verbose :%level;
  
  %*ENV
    ==> grep( *.key.starts-with( any <RAKU PAKKU> ) )
    ==> map( -> $env { log '🐝', header => 'ENV', msg => $env.key,  comment => $env.value } );

  log '🐝', header => 'CNF', msg => 'verbose', comment => ~$verbose;
  log '🐝', header => 'CNF', msg => 'bar',     comment => ~$bar;
  log '🐝', header => 'CNF', msg => 'spinner', comment => ~$spinner;

  log '🐝', header => 'CNF', msg => 'home', comment => ~$!home;

  $!stage  = $!home.add( '.stage' );

  log '🐝', header => 'CNF', msg => 'stage', comment => ~$!stage;

  my $cache-conf = %!cnf<pakku><cache>; 
  my $cache-dir  = $!home.add( '.cache' ); 

  with $cache-conf {
    $cache-dir = $cache-conf unless $cache-conf === True;  
  }

  $!cache = Pakku::Cache.new:  :$cache-dir if $cache-dir;

  log '🐝', header => 'CNF', msg => 'cache', comment => ~$cache-dir;

  $!tmp = $!home.add( '.tmp' );

  log '🐝', header => 'CNF', msg => 'tmp', comment => ~$!tmp;

  $!dont  = %!cnf<pakku><dont> // False;

  log '🐝', header => 'CNF', msg => 'dont', comment => ~$!dont;

  $!force  = %!cnf<pakku><force> // False;

  log '🐝', header => 'CNF', msg => 'force', comment => ~$!force;

  $!yolo  = %!cnf<pakku><yolo> // False;

  log '🐝', header => 'CNF', msg => 'yolo', comment => ~$!yolo;

  die X::Pakku::Cnf.new: msg => 'cores', comment => "$cores: not a positive integer!" unless $cores ~~ Int:D | /^ \d+ $/ and +$cores > 0;

  $!cores  = +$cores;

  log '🐝', header => 'CNF', msg => 'cores', comment => ~$!cores;

  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  log '🐝', header => 'CNF', msg => 'degree', comment => ~$!degree;

  my $recman   = %!cnf<pakku><recman>;
  my $norecman = %!cnf<pakku><norecman>;

  my @recman = ( %!cnf<recman> // [] ).flat;

  @recman .= grep: { .<name> !~~ $norecman } if $norecman;
  @recman .= grep: { .<name>  ~~ $recman   } if $recman;

  $!fetch  = Pakku::Fetch.new;

  $!recman = Pakku::Recman.new: :$!fetch, store => $!home.add( '.index' ), :@recman, refresh => %!cnf<pakku><refresh> if @recman;

  # an old config file may list only the retired recman.pakku.org: fall back to the built-in ecosystems
  if @recman and not $!recman.names and not ( $recman ~~ Str or $norecman ) {

    log '🐞', header => 'REC', msg => 'config', comment => 'no usable recman configured, using the built-in ecosystems (pakku config recman reset)';

    @recman = Rakudo::Internals::JSON.from-json( %?RESOURCES<config.json>.slurp )<recman>.flat;

    $!recman = Pakku::Recman.new: :$!fetch, store => $!home.add( '.index' ), :@recman, refresh => %!cnf<pakku><refresh>;

  }

  @recman.map( -> $recman { log '🐝', header => 'CNF', msg => 'recman', comment => $recman<name> ~ ' ' ~ ( $recman<mirrors> // $recman<location> // '' ).List.map( { redact ~$_ } ).join( ' ' ) } );

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );

  log '🐝', header => 'CNF', msg => 'repos', comment => ~@!repo;

}


method metamorph ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd { .log; nofun; exit 1 }

      when X::Pakku::Cnf { .log; nofun; exit 1 }

      default { log '🦗', header => 'CNF', msg => .gist, :!msg-delimit; nofun; exit 1 }
  }

  my $home = $*HOME.add( '.pakku' );

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::CmdActions );

  die X::Pakku::Cmd.new: msg => ~@*ARGS, comment => 'unknown command or option, see: pakku help' unless $cmd;

  my %cmd = $cmd.made;

  my %env = get-env;

  my %cnf = hashmerge %env, %cmd;

  my %default = Rakudo::Internals::JSON.from-json: %?RESOURCES<config.json>.slurp;


  if %cnf<pakku><config>:exists {

    die X::Pakku::Cnf.new: msg => ~%cnf<pakku><config> unless %cnf<pakku><config>.IO.f;

  }

  %cnf<pakku><config> //= $home.add( 'config.json' );

  my $config-file = %cnf<pakku><config>.IO;

  if $config-file.f {

    my $cnf = Rakudo::Internals::JSON.from-json: slurp $config-file.IO;

    die X::Pakku::Cnf.new: msg => ~$config-file unless defined $cnf;

    %cnf =  hashmerge $cnf, %cnf;

  }

  %cnf = hashmerge %default, %cnf;

  %cnf<pakku><home> = $home;

  self.bless( :%cnf );

}

# borrowed from Hash::Merge:cpan:TYIL to fix #6
# deep merge, the source wins; a hash only merges into a hash (a null in a config file replaces, it does not crash)
my sub hashmerge ( %merge-into, %merge-source ) {

  for %merge-source.keys -> $key {
    if %merge-into{ $key } ~~ Hash and %merge-source{ $key } ~~ Hash {
      hashmerge %merge-into{ $key }, %merge-source{ $key };
    }
    else { %merge-into{ $key } = %merge-source{ $key } }
  }

  %merge-into;
}

my sub repo-from-spec ( Str $spec ) {

  return CompUnit::RepositoryRegistry.repository-for-name( $spec ) if $spec ~~ any <home site vendor core>;

  return CompUnit::Repository unless $spec;

  my $repo-spec = CompUnit::Repository::Spec.from-string( $spec, 'inst' );
  my $name = $repo-spec.options<name> // 'custom-lib';

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec( $repo-spec );

  CompUnit::RepositoryRegistry.register-name( $name, $repo );

  $repo;
}

my sub find-perl-module ( Str:D $name --> Bool:D ) {

  return True if run('perl', "-M$name", '-e 1', :err).exitcode == 0;

  return False;
}

# PAKKU_* environment variables, lowest precedence after the built-in defaults
my sub get-env ( ) {

  my %env;

  my sub bool ( Str:D $name, Str:D $value ) {
    given $value.lc {
      when '1' | 'true'  | 'yes' | 'on'  { True  }
      when '0' | 'false' | 'no'  | 'off' | '' { False }
      default { die X::Pakku::Cnf.new: msg => $name, comment => "$value: not a boolean (true/false)!" }
    }
  }

  my sub deps ( Str:D $value ) { $value eq 'only' ?? 'only' !! bool( 'deps', $value ) }

  my sub positive ( Str:D $name, Str:D $value ) { $value ~~ / ^ \d+ $ / && +$value > 0 ?? +$value !! die X::Pakku::Cnf.new: msg => $name, comment => "$value: not a positive integer!" }

  # general: name => [ config key, converter ]
  my %general =
    PAKKU_VERBOSE  => [ 'verbose',  { $_ } ],
    PAKKU_CORES    => [ 'cores',    { positive 'PAKKU_CORES', $_ } ],
    PAKKU_RECMAN   => [ 'recman',   { $_ ~~ / ^ [ true | 1 ] $ / ?? True !! $_ } ],
    PAKKU_NORECMAN => [ 'norecman', { $_ ~~ / ^ [ true | 1 ] $ / ?? True !! $_ } ],
    PAKKU_CONFIG   => [ 'config',   { .IO } ],
    PAKKU_CACHE    => [ 'cache',    { $_ ~~ / ^ [ 0 | 1 | true | false | yes | no | on | off ] $ / ?? bool( 'PAKKU_CACHE', $_ ) !! $_ } ],
    PAKKU_DONT     => [ 'dont',     { bool 'PAKKU_DONT',    $_ } ],
    PAKKU_FORCE    => [ 'force',    { bool 'PAKKU_FORCE',   $_ } ],
    PAKKU_YOLO     => [ 'yolo',     { bool 'PAKKU_YOLO',    $_ } ],
    PAKKU_PRETTY   => [ 'pretty',   { bool 'PAKKU_PRETTY',  $_ } ],
    PAKKU_ASYNC    => [ 'async',    { bool 'PAKKU_ASYNC',   $_ } ],
    PAKKU_BAR      => [ 'bar',      { bool 'PAKKU_BAR',     $_ } ],
    PAKKU_SPINNER  => [ 'spinner',  { bool 'PAKKU_SPINNER', $_ } ],
    PAKKU_REFRESH  => [ 'refresh',  { bool 'PAKKU_REFRESH', $_ } ];

  for %general.sort -> ( :key($name), :value(( $key, &convert )) ) {
    %env<pakku>{ $key } = convert( %*ENV{ $name } ) if %*ENV{ $name }:exists;
  }

  # per command: PAKKU_<COMMAND>_<OPTION>, stored under the command (that is where fly() reads them)
  my %command =
    add      => %( to => { $_ }, deps => &deps, test => &bool.assuming( 'PAKKU_ADD_TEST' ), build => &bool.assuming( 'PAKKU_ADD_BUILD' ), serial => &bool.assuming( 'PAKKU_ADD_SERIAL' ), contained => &bool.assuming( 'PAKKU_ADD_CONTAINED' ), xtest => &bool.assuming( 'PAKKU_ADD_XTEST' ), precompile => &bool.assuming( 'PAKKU_ADD_PRECOMPILE' ), exclude => { .split( / \s+ / ).Array } ),
    update   => %( in => { $_ }, deps => &deps, test => &bool.assuming( 'PAKKU_UPDATE_TEST' ), build => &bool.assuming( 'PAKKU_UPDATE_BUILD' ), xtest => &bool.assuming( 'PAKKU_UPDATE_XTEST' ), clean => &bool.assuming( 'PAKKU_UPDATE_CLEAN' ), precompile => &bool.assuming( 'PAKKU_UPDATE_PRECOMPILE' ), exclude => { .split( / \s+ / ).Array } ),
    test     => %( build => &bool.assuming( 'PAKKU_TEST_BUILD' ), xtest => &bool.assuming( 'PAKKU_TEST_XTEST' ) ),
    remove   => %( from => { $_ } ),
    list     => %( repo => { $_ }, details => &bool.assuming( 'PAKKU_LIST_DETAILS' ) ),
    search   => %( count => { positive 'PAKKU_SEARCH_COUNT', $_ }, latest => &bool.assuming( 'PAKKU_SEARCH_LATEST' ), details => &bool.assuming( 'PAKKU_SEARCH_DETAILS' ), relaxed => &bool.assuming( 'PAKKU_SEARCH_RELAXED' ) ),
    state    => %( clean => &bool.assuming( 'PAKKU_STATE_CLEAN' ), updates => &bool.assuming( 'PAKKU_STATE_UPDATES' ) );

  for %command.sort -> ( :key($command), :value(%option) ) {
    for %option.sort -> ( :key($option), :value(&convert) ) {
      my $name = 'PAKKU_' ~ $command.uc ~ '_' ~ $option.uc;
      %env{ $command }{ $option } = convert( %*ENV{ $name } ) if %*ENV{ $name }:exists;
    }
  }

  %env;

}

