use CompUnit::Repository::Staging;

use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Cache;
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
has Pakku::HTTP   $!http;
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
method !http   { $!http   }
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

  my $meta = try Pakku::Meta.new(
    ( $!cache.recommend( :$spec ).meta if $!cache  ) //
    ( $!recman.recommend: :$spec       if $!recman )
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

multi method satisfy ( :@spec! ) {

  log '🐛', header => 'SPC', msg => {~@spec}, comment => 'satisfying!';

  my $meta =
    @spec.map( -> $spec {

      log '🐛', header => 'SPC', msg => ~$spec, comment => 'trying!';

      my $meta = try samewith :$spec;

      return $meta if $meta;

    } );

  die X::Pakku::Spec.new: msg => ~@spec unless $meta;;

  log '🐞', header => 'OLO', msg => {~@spec};

  Empty
}


multi method satisfied ( Pakku::Spec::Raku:D   :$spec! --> Bool:D ) {

  my $name = $spec.name;
  my %spec = $spec.spec;

  return False unless @!repo.first( *.candidates: $name, |%spec );

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

multi method satisfied ( :@spec! --> Bool:D ) { so @spec.first( -> $spec { samewith :$spec } ) }

method get-deps ( Pakku::Meta:D $meta, :$deps = True, Bool:D :$contained = False, :@exclude ) {

  state %visited = @exclude.map: *.id => True;

  $meta.deps( :$deps )
    ==> grep( -> $spec { quietly %visited{ $spec.?id }:!exists } )
    ==> grep( -> $spec { $contained and $spec ~~ Pakku::Spec::Raku or not self.satisfied( :$spec ) } )
    ==> map(  -> $spec {

    my $meta = self.satisfy: :$spec;

    quietly %visited{ $spec.?id  } = True;

    self.get-deps( $meta, :$deps, :$contained ), $meta if $meta;

  } )

}


# TODO: subset TarGzURL of Str
multi method fetch ( Str:D :$src!, IO::Path:D :$dst! ) {

  log '🐛', header => 'FTC', msg => ~$src;

  log '🐝', header => 'FTC', msg => ~$src, comment => ~$dst;


  mkdir $dst;

  my $archive = $dst.add( $dst.basename ~ '.tar.gz' );

   my $response;

  try retry {

    $response = $!http.download: url-encode( $src ), $archive;

    die X::Pakku::HTTP.new: :$response, message => $response<reason> unless $response<success>;

  }

  die X::Pakku::Fetch.new: msg => ~$src unless $response<success>;

  log '🐛', header => 'EXT', msg => ~$archive;

  my $extract = extract :$archive, :$dst;

  die X::Pakku::Archive.new: msg => ~$archive unless $extract;

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

      $!recman.search( :spec( Pakku::Spec.new: $meta.name ) :!relaxed :!latest :42count )
        ==> grep( *.defined )
        ==> grep( -> %meta { $meta.name       ~~ %meta.<name> } )
        ==> grep( -> %meta { $meta.meta<auth> ~~ %meta.<auth> } )
        ==> grep( -> %meta {
              ( quietly Version.new( %meta<version> ) cmp Version.new( $meta.meta<version> ) or  
                quietly Version.new( %meta<api>     ) cmp Version.new( $meta.meta<api>     )  
              ) ~~ More
            } )
        ==> sort( -> %left, %right {

              quietly ( Version.new( %right<version> ) cmp Version.new( %left<version> ) ) or 
              quietly ( Version.new( %right<api> )     cmp Version.new( %left<api> ) );

            } )
        ==> map( -> %meta { Pakku::Meta.new: %meta } )
        ==> grep( -> $meta { not self.satisfied: spec => Pakku::Spec.new: ~$meta } )
        ==> my @upd if $updates and $!recman;

      if @upd {
        %state{ $meta  }.<upd> .append: @upd;
      }

      sink $meta.deps( :deps ).grep( Pakku::Spec::Raku ).grep( *.name.so ).map( -> $spec {

        log '🐛', header => 'SPC', msg => ~$spec;

        @!repo
          ==> map( -> $repo { $repo.candidates( $spec.name , |$spec.spec ).head } )
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

  $!cores  = +$cores;

  log '🐝', header => 'CNF', msg => 'cores', comment => ~$!cores;

  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  log '🐝', header => 'CNF', msg => 'degree', comment => ~$!degree;

  my $recman   = %!cnf<pakku><recman>;
  my $norecman = %!cnf<pakku><norecman>;

  my @recman = %!cnf<recman> ?? %!cnf<recman>.flat !! ( %( :name<pakku>, :location<http://recman.pakku.org>, :1priority, :active ), );

  @recman .= grep: { .<name> !~~ $norecman } if $norecman;
  @recman .= grep: { .<name>  ~~ $recman   } if $recman;

  $!http  = Pakku::HTTP.new;

  $!recman = Pakku::Recman.new: :$!http :@recman if @recman;

  @recman.map( -> $recman { log '🐝', header => 'CNF', msg => 'recman', comment => $recman<location> } );

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );

  log '🐝', header => 'CNF', msg => 'repos', comment => ~@!repo;

}


method metamorph ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd {

        my $cmd = Pakku::Grammar::Cmd.subparse( @*ARGS, actions => Pakku::Grammar::CmdActions ).made<cmd>;

        self.fly: 'help', :$cmd;

        .message;

        nofun;
      }

      when X::Pakku::Cnf { log '🦗', header => 'CNF', msg => .message; nofun; exit 1 }

      default { log '🦗', header => 'CNF', msg => .gist }
  }

  my $home = $*HOME.add( '.pakku' );

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::CmdActions );

  die X::Pakku::Cmd.new: msg => ~@*ARGS unless $cmd;

  my %cmd = $cmd.made;

  my %env = get-env;

  my %cnf = hashmerge %env, %cmd;


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

  %cnf<pakku><home> = $home;

  self.bless( :%cnf );

}

# borrowed from Hash::Merge:cpan:TYIL to fix #6
my sub hashmerge ( %merge-into, %merge-source ) {

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

my sub repo-from-spec ( Str $spec ) {

  return CompUnit::RepositoryRegistry.repository-for-name( $spec ) if $spec ~~ any <home site vendor core>;

  return CompUnit::Repository unless $spec;

  my $repo-spec = CompUnit::Repository::Spec.from-string( $spec, 'inst' );
  my $name = $repo-spec.options<name> // 'custom-lib';

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec( $repo-spec );

  CompUnit::RepositoryRegistry.register-name( $name, $repo );

  $repo;
}

my sub find-bin ( Str:D $name --> Bool:D ) {

  so $*SPEC.path.first( -> $path {
    $*SPEC.catfile( $path, $name ).IO.f or ( $*SPEC.catfile( $path, $name ~ '.exe'  ).IO.f if $*DISTRO.is-win )
  } )

}

my sub find-perl-module ( Str:D $name --> Bool:D ) {

  return True if run('perl', "-M$name", '-e 1', :err).exitcode == 0;

  return False;
}

sub copy-dir ( IO::Path:D :$src!, IO::Path:D :$dst! --> Nil ) {

  my $relpath := $src.chars;

  for Rakudo::Internals.DIR-RECURSE( ~$src ) -> $path {

    my $destination := $dst.add( $path.substr( $relpath ) );

    $destination.parent.mkdir;

    $path.IO.copy: $destination;

  }
}

my sub remove-dir( IO::Path:D $io --> Nil ) is export {
  .d ?? remove-dir( $_ ) !! .unlink for $io.dir;
  $io.rmdir;
}

my sub url-encode ( Str() $text --> Str ) {
  return $text.subst:
    /<-[
      ! ' ( ) ; : @ $ , / ? # \[ \]
      0..9 A..Z a..z . ~ _
    ]> /,
      { .Str.encode».fmt('%%%02X').join }, :g;
}

my sub get-env ( ) {

  my %env;

  %env<pakku><cache>    = %*ENV<PAKKU_CACHE>        if %*ENV<PAKKU_CACHE>;
  %env<pakku><verbose>  = %*ENV<PAKKU_VERBOSE>      if %*ENV<PAKKU_VERBOSE>;
  %env<pakku><cores>    = %*ENV<PAKKU_CORES>        if %*ENV<PAKKU_CORES>;
  %env<pakku><recman>   = %*ENV<PAKKU_RECMAN>       if %*ENV<PAKKU_RECMAN>;
  %env<pakku><norecman> = %*ENV<PAKKU_NORECMAN>     if %*ENV<PAKKU_NORECMAN>;
  %env<pakku><config >  = %*ENV<PAKKU_CONFIG>.IO    if %*ENV<PAKKU_CONFIG>;
  %env<pakku><dont>     = %*ENV<PAKKU_DONT>.Bool    if %*ENV<PAKKU_DONT>;
  %env<pakku><force>    = %*ENV<PAKKU_FORCE>.Bool   if %*ENV<PAKKU_FORCE>;
  %env<pakku><yolo>     = %*ENV<PAKKU_YOLO>.Bool    if %*ENV<PAKKU_YOLO>;
  %env<pakku><pretty>   = %*ENV<PAKKU_PRETTY>.Bool  if %*ENV<PAKKU_PRETTY>;
  %env<pakku><async>    = %*ENV<PAKKU_ASYNC>.Bool   if %*ENV<PAKKU_ASYNC>;
  %env<pakku><bar>      = %*ENV<PAKKU_BAR>.Bool     if %*ENV<PAKKU_BAR>;
  %env<pakku><spinner>  = %*ENV<PAKKU_SPINNER>.Bool if %*ENV<PAKKU_SPINNER>;

  %env<pakku><add><to>         = %*ENV<PAKKU_ADD_TO>                       if %*ENV<PAKKU_ADD_TO>;
  %env<pakku><add><deps>       = %*ENV<PAKKU_ADD_DEPS>                     if %*ENV<PAKKU_ADD_DEPS>;
  %env<pakku><add><test>       = %*ENV<PAKKU_ADD_TEST>.Bool                if %*ENV<PAKKU_ADD_TEST>;
  %env<pakku><add><build>      = %*ENV<PAKKU_ADD_BUILD>.Bool               if %*ENV<PAKKU_ADD_BUILD>;
  %env<pakku><add><serial>     = %*ENV<PAKKU_ADD_SERIAL>.Bool              if %*ENV<PAKKU_ADD_SERIAL>;
  %env<pakku><add><contained>  = %*ENV<PAKKU_ADD_CONTAINED>.Bool           if %*ENV<PAKKU_ADD_CONTAINED>;
  %env<pakku><add><xtest>      = %*ENV<PAKKU_ADD_XTEST>.Bool               if %*ENV<PAKKU_ADD_XTEST>;
  %env<pakku><add><precompile> = %*ENV<PAKKU_ADD_PRECOMPILE>.Bool          if %*ENV<PAKKU_ADD_PRECOMPILE>;
  %env<pakku><add><exclude>    = %*ENV<PAKKU_ADD_EXCLUDE>.split( / \s+ / ) if %*ENV<PAKKU_ADD_EXCLUDE>;

  %env<pakku><test><build> = %*ENV<PAKKU_TEST_BUILD>.Bool if %*ENV<PAKKU_TEST_BUILD>;
  %env<pakku><test><xtest> = %*ENV<PAKKU_TEST_XTEST>.Bool if %*ENV<PAKKU_TEST_XTEST>;

  %env<pakku><remove><from> = %*ENV<PAKKU_REMOVE_FROM> if %*ENV<PAKKU_REMOVE_FROM>;

  %env<pakku><list><repo>    = %*ENV<PAKKU_LIST_REPO>         if %*ENV<PAKKU_LIST_REPO>;
  %env<pakku><list><details> = %*ENV<PAKKU_LIST_DETAILS>.Bool if %*ENV<PAKKU_LIST_DETAILS>;

  %env<pakku><search><count>   = %*ENV<PAKKU_SEARCH_count>.Int    if %*ENV<PAKKU_SEARCH_COUNT>;
  %env<pakku><search><latest>  = %*ENV<PAKKU_SEARCH_LATEST>.Bool  if %*ENV<PAKKU_SEARCH_LATEST>;
  %env<pakku><search><details> = %*ENV<PAKKU_SEARCH_DETAILS>.Bool if %*ENV<PAKKU_SEARCH_DETAILS>;
  %env<pakku><search><relaxed> = %*ENV<PAKKU_SEARCH_RELAXED>.Bool if %*ENV<PAKKU_SEARCH_RELAXED>;

  %env<pakku><update><in>         = %*ENV<PAKKU_UPDATE_IN>                       if %*ENV<PAKKU_UPDATE_IN>;
  %env<pakku><update><deps>       = %*ENV<PAKKU_UPDATE_DEPS>                     if %*ENV<PAKKU_UPDATE_DEPS>;
  %env<pakku><update><test>       = %*ENV<PAKKU_UPDATE_TEST>.Bool                if %*ENV<PAKKU_UPDATE_TEST>;
  %env<pakku><update><xtest>      = %*ENV<PAKKU_UPDATE_XTEST>.Bool               if %*ENV<PAKKU_UPDATE_XTEST>;
  %env<pakku><update><build>      = %*ENV<PAKKU_UPDATE_BUILD>.Bool               if %*ENV<PAKKU_UPDATE_BUILD>;
  %env<pakku><update><clean>      = %*ENV<PAKKU_UPDATE_CLEAN>.Bool               if %*ENV<PAKKU_UPDATE_CLEAN>;
  %env<pakku><update><precompile> = %*ENV<PAKKU_UPDATE_PRECOMPILE>.Bool          if %*ENV<PAKKU_UPDATE_PRECOMPILE>;
  %env<pakku><update><exclude>    = %*ENV<PAKKU_UPDATE_EXCLUDE>.split( / \s+ / ) if %*ENV<PAKKU_UPDATE_EXCLUDE>;


  %env<pakku><state><clean>   = %*ENV<PAKKU_STATE_CLEAN>.Bool   if %*ENV<PAKKU_STATE_CLEAN>;
  %env<pakku><state><updates> = %*ENV<PAKKU_STATE_UPDATES>.Bool if %*ENV<PAKKU_STATE_UPDATES>;

 %env;

}

sub retry (

          &action,
  Int:D  :$max   is copy = 4,
  Real:D :$delay is copy = 0.2

) is export {

  loop {

    my $result = quietly try action();

    return $result unless $!;

    $!.rethrow if $max == 0;

    sleep $delay;

    log '🐞', header => 'TRY', msg => ~$!, :comment<retrying!>;

    $delay *= 2;
    $max   -= 1;

  }

}
