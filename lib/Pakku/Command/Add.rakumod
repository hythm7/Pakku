use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Add;


multi method fly (

         'add',
         :@spec!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$serial     = False,
  Bool:D :$contained  = False,
  Str:D  :$to         = 'site',
         :@exclude,

) {


  log '🧚', header => 'ADD', msg => ~@spec;

  my $repo = self.repo-from-spec: spec => $to;

  unless $repo.can-install {

    log '🐞', header => 'REP', msg => ~$repo.prefix, comment => 'can not install!';

    $repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation ).first( *.can-install );

    log '🐞', header => 'REP', msg => ~$repo, comment => 'will be used!' if $repo;

    die X::Pakku::Add.new: msg => ~@spec unless $repo;

  }

  @spec
    ==> map(  -> $spec { Pakku::Spec.new: $spec } )
    ==> grep( -> $spec { self!force or not self.satisfied: :$spec } )
    ==> unique( as => *.Str )
    ==> map(  -> $spec { self.satisfy: :$spec } )
    ==> map(  -> $meta {

      my @meta = flat self.get-deps: $meta, :$deps, :$contained, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );

      @meta .= unique( as => *.Str );

      @meta.append: $meta unless $deps ~~ <only>;

      @meta;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  unless @meta {

    log '🧚', header => 'ADD', msg => ~@spec, comment => 'already added!';

    return;

  }

  my @dist = @meta.hyper( degree => self!degree, :1batch ).map( -> $meta {

    log '🦋', header => 'FTC', msg => ~$meta;

    my IO::Path $path = self!tmp.add( $meta.id ).add( now.Num );

    my $cached = self!cache.cached( :$meta ) if self!cache;

    if $cached {

      self.copy-dir: src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      log '🧚', header => 'FTC', msg => ~$meta;

      self!cache.cache: :$path if self!cache;
    }

    $meta.to-dist: $path;

  } );

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $*REPO;

  my $precomp-dir = $stage.prefix.add( 'precomp' ).add( $*RAKU.compiler.id );
  my $dist-dir    = $stage.prefix.add: 'dist';

  $precomp-dir.mkdir;
  $dist-dir.mkdir;

  if $serial {

    my $precomp-supply = watch-recursive( $precomp-dir );
    my $dist-supply    = $dist-dir.watch;

    eager @dist 
      ==> map( -> $dist {
  
        self.build: :$stage :$dist if $build;

        bar.header: 'STG';
        bar.length: $dist.Str.chars;
        bar.sym:    $dist.Str;
        bar.activate;

        my $processed = 0;
        my $total     = +$dist.meta<provides>.keys;
        my $dist-meta-file = $dist-dir.add( $dist.id );

        my %hash-to-name;

        my $dist-tap = $dist-supply.tap( -> $event {

          if $event.path ~~  $dist-meta-file and $event.event ~~ FileChanged {

            my %provides = Rakudo::Internals::JSON.from-json( $dist-meta-file.slurp ).<provides>;

            %provides.map( { %hash-to-name{ .value.values.head.<file> } = .key } );

          }


        } );

        my $precomp-tap = $precomp-supply.tap( -> $event {

        log '🦋', header => 'CMP', msg => %hash-to-name{ $event.path.IO.basename };

        $processed += 1;

        my $percent = $processed / $total * 100;

        bar.percent: $percent;

        bar.show;

        } );

        $stage.install: $dist, :$precompile;

        $dist-tap.close;

        $precomp-tap.close;

        bar.deactivate;

        log '🧚', header => 'STG', msg => ~$dist;

        self.test: :$stage :$dist :$xtest if $test;

        unless self!dont {

          try $stage.remove-artifacts; # trying for Windows

          $stage.deploy;

          my $bin = $stage.prefix.add( 'bin' ).Str;

          my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

          log '🐛', header => 'BIN', msg => ~$repo.prefix.add( 'bin' ), comment => 'binaries added!' if @bin;

          @bin.sort.map( -> $bin { log '🧚', header => 'BIN', msg => $bin.IO.basename } ).eager;

          try $stage.self-destruct; # trying for Windows

          $precomp-dir.mkdir;
          $dist-dir.mkdir;

        }

      } );

  } else {

    my $precomp-supply = watch-recursive( $precomp-dir ).share;
    my $dist-supply    = $dist-dir.watch;

    @dist 
      ==> map( -> $dist {

        self.build: :$stage :$dist if $build;

        bar.header: 'STG';
        bar.length: $dist.Str.chars;
        bar.sym:    $dist.Str;
        bar.activate;

        my $processed = 0;
        my $total     = +$dist.meta<provides>.keys;


        my $dist-meta-file = $dist-dir.add( $dist.id );

        my %hash-to-name;

        my $dist-tap = $dist-supply.tap( -> $event {

          if $event.path ~~  $dist-meta-file and $event.event ~~ FileChanged { 

            my %provides = Rakudo::Internals::JSON.from-json( $dist-meta-file.slurp ).<provides>;

            %provides.map( { %hash-to-name{ .value.values.head.<file> } = .key } );

          }


        } );

        my $precomp-tap = $precomp-supply.tap( -> $event {

        log '🦋', header => 'CMP', msg => %hash-to-name{ $event.path.IO.basename };

        $processed += 1;

        my $percent = $processed / $total * 100;

        bar.percent: $percent;

        bar.show;

        } );

        $stage.install: $dist, :$precompile;

        $dist-tap.close;
        $precomp-tap.close;

        bar.deactivate;

        log '🧚', header => 'STG', msg => ~$dist;

        self.test: :$stage :$dist :$xtest if $test;

      } );

    unless self!dont {

      try $stage.remove-artifacts; # trying for Windows

      $stage.deploy if @dist;

      my $bin = $stage.prefix.add( 'bin' ).Str;

      my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

      log '🐛', header => 'BIN', msg => ~$repo.prefix.add( 'bin' ), comment => 'binaries added!' if @bin;

      @bin.sort.map( -> $bin { log '🧚', header => 'BIN', msg => $bin.IO.basename } ).eager;

    }
  }
}

multi method fly (

         'add',
  IO:D   :$path!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$serial     = False,
  Bool:D :$contained  = False,
  Str:D  :$to         = 'site',
         :@exclude,

) {

  log '🧚', header => 'ADD', msg => ~$path;

  my $repo = self.repo-from-spec: spec => $to;

  unless $repo.can-install {

    log '🐞', header => 'REP', msg => ~$repo.prefix, comment => 'can not install!';

    $repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation ).first( *.can-install );

    log '🐞', header => 'REP', msg => ~$repo.prefix, comment => 'will be used!' if $repo;

    die X::Pakku::Add.new: msg => ~$path unless $repo;

  }

  my $spec = Pakku::Spec.new: $path;

  if not self!force and self.satisfied( :$spec ) {
    log '🧚', header => 'ADD', msg => ~$spec, comment => 'already added!';
    return;
  }

  my $meta = Pakku::Meta.new: $path;

  my @meta = flat self.get-deps: $meta, :$deps, :$contained, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );

  @meta .= unique( as => *.Str );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.hyper( degree => self!degree, :1batch ).map( -> $meta {

    log '🦋', header => 'FTC', msg => ~$meta;

    my IO::Path $path = self!tmp.add( $meta.id ).add( now.Num );

    my $cached = self!cache.cached( :$meta ) if self!cache;

    if $cached {

      self.copy-dir: src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      self!cache.cache: :$path if self!cache;
    }

    $meta.to-dist: $path;

  } );

  @dist.append: $dist unless $deps ~~ <only>;

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $*REPO;

  my $precomp-dir = $stage.prefix.add( 'precomp' ).add( $*RAKU.compiler.id );

  my $dist-dir    = $stage.prefix.add: 'dist';

  $precomp-dir.mkdir;
  $dist-dir.mkdir;

  if $serial {

    my $precomp-supply = watch-recursive( $precomp-dir );
    my $dist-supply    = $dist-dir.watch;

    eager @dist 
      ==> map( -> $dist {
  
        self.build: :$stage :$dist if $build;

        bar.header: 'STG';
        bar.length: $dist.Str.chars;
        bar.sym:    $dist.Str;
        bar.activate;

        my $processed = 0;
        my $total     = +$dist.meta<provides>.keys;

        my $dist-meta-file = $dist-dir.add( $dist.id );

        my %hash-to-name;

        my $dist-tap = $dist-supply.tap( -> $event {

          if $event.path ~~  $dist-meta-file and $event.event ~~ FileChanged {

            my %provides = Rakudo::Internals::JSON.from-json( $dist-meta-file.slurp ).<provides>;

            %provides.map( { %hash-to-name{ .value.values.head.<file> } = .key } );

          }

        } );

        my $precomp-tap = $precomp-supply.tap( -> $event {

        log '🦋', header => 'CMP', msg => %hash-to-name{ $event.path.IO.basename };

        $processed += 1;

        my $percent = $processed / $total * 100;

        bar.percent: $percent;

        bar.show;

        } );

        $stage.install: $dist, :$precompile;

        $dist-tap.close;
        $precomp-tap.close;

        bar.deactivate;

        log '🧚', header => 'STG', msg => ~$dist;

        self.test: :$stage :$dist :$xtest if $test;

        unless self!dont {

          try $stage.remove-artifacts; # trying for Windows

          $stage.deploy;

          my $bin = $stage.prefix.add( 'bin' ).Str;

          my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

          log '🐛', header => 'BIN', msg => ~$repo.prefix.add( 'bin' ), comment => 'binaries added!' if @bin;

          @bin.sort.map( -> $bin { log '🧚', header => 'BIN', msg => $bin.IO.basename } ).eager;

          try $stage.self-destruct; # trying for Windows

          $precomp-dir.mkdir;
          $dist-dir.mkdir;

        }

      } );

  } else {

    my $precomp-supply = watch-recursive( $precomp-dir ).share;
    my $dist-supply    = $dist-dir.watch;

    @dist 
      ==> map( -> $dist {
  
        self.build: :$stage :$dist if $build;

        bar.header: 'STG';
        bar.length: $dist.Str.chars;
        bar.sym:    $dist.Str;
        bar.activate;

        my $processed = 0;
        my $total     = +$dist.meta<provides>.keys;

        my $dist-meta-file = $dist-dir.add( $dist.id );

        my %hash-to-name;

        my $dist-tap = $dist-supply.tap( -> $event {

          if $event.path ~~  $dist-meta-file and $event.event ~~ FileChanged {

            my %provides = Rakudo::Internals::JSON.from-json( $dist-meta-file.slurp ).<provides>;

            %provides.map( { %hash-to-name{ .value.values.head.<file> } = .key } );

          }


        } );

        my $precomp-tap = $precomp-supply.tap( -> $event {

        log '🦋', header => 'CMP', msg => %hash-to-name{ $event.path.IO.basename };

        $processed += 1;

        my $percent = $processed / $total * 100;

        bar.percent: $percent;

        bar.show;

        } );

        $stage.install: $dist, :$precompile;

        $dist-tap.close;

        $precomp-tap.close;

        bar.deactivate;

        log '🧚', header => 'STG', msg => ~$dist;

        self.test: :$stage :$dist :$xtest if $test;

      } );

    unless self!dont {

      try $stage.remove-artifacts; # trying for Windows

      $stage.deploy if @dist;

      my $bin = $stage.prefix.add( 'bin' ).Str;

      my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

      log '🐛', header => 'BIN', msg => ~$repo.prefix.add( 'bin' ), comment => 'binaries added!' if @bin;

      @bin.sort.map( -> $bin { log '🧚', header => 'BIN', msg => $bin.IO.basename } ).eager;

    }
  }
}

my sub watch-recursive ( IO $start ) {

  my %precompiled;

  supply {

    my sub watch ( IO::Path:D $io ) {

      whenever $io.watch -> $e {

        CATCH { default { .so } }

        next unless $e.event ~~ FileRenamed;

        if $e.path.IO.d {
          watch( $e.path.IO.resolve );
          next;
        }

        unless $e.path.IO.extension {

          my $path = $e.path;

          emit $e unless %precompiled{ $path };

          %precompiled{ $path } = True;

        }
      }
    }

    watch( $start );
  }
}

