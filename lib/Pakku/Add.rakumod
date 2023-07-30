use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Add;


multi method fly (

         'add',
         :@spec!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
  Str:D  :$to         = 'site',
         :@exclude,

) {


  🧚 qq[ADD: ｢{@spec}｣];

  @spec
    ==> map(  -> $spec { Pakku::Spec.new: $spec } )
    ==> grep( -> $spec { $force or not self.satisfied: :$spec } )
    ==> unique( as => *.Str )
    ==> map(  -> $spec { self.satisfy: :$spec } )
    ==> map(  -> $meta {

      my @meta = flat self.get-deps: $meta, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );

      @meta .= unique( as => *.Str );

      @meta.append: $meta unless $deps ~~ <only>;

      @meta;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  unless @meta {

    🧚 qq[ADD: ｢{@spec}｣ already added!];

    return;

  }

  my @dist = @meta.map( -> $meta {

    🦋 qq[FTC: ｢$meta｣];

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

  my $repo = self.repo-from-spec: spec => $to;

  unless $repo.can-install {

    🐞 qq[REP: ｢$repo｣ can not install!];

    $repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation ).first( *.can-install );

    🐞 qq[REP: ｢$repo｣ will be used!] if $repo ;

    die X::Pakku::Add.new: dist => @spec unless $repo;

  }

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self.build: :$dist if $build;

      🦋 qq[STG: ｢$dist｣];

      $*stage.install: $dist, :$precompile;

      self.test: :$dist :$xtest if $test;

    } );

  $*stage.remove-artifacts;

  unless self!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

      🐛 qq[BIN: ｢{ $repo.prefix.add( 'bin' ) }｣ binaries added!] if @bin;

      @bin.map( -> $bin { 🧚 qq[BIN: ｢{ $bin.IO.basename }｣] } ).eager;

    }
  }
}

multi method fly (

         'add',
  IO:D   :$path!,
         :$deps       = True,
  Str:D  :$to         = 'site',
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
         :@exclude,

) {

  🧚 qq[ADD: ｢$path｣];

  my $spec = Pakku::Spec.new: $path;

  if not $force and self.satisfied( :$spec ) {

    🧚 qq[ADD: ｢$spec｣ already added!];

    return;
  }

  my $meta = Pakku::Meta.new: $path;

  my @meta = flat self.get-deps: $meta, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );

  @meta .= unique( as => *.Str );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.map( -> $meta {

    🦋 qq[FTC: ｢$meta｣];

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

  my $repo = self.repo-from-spec: spec => $to;

  unless $repo.can-install {

    🐞 qq[REP: ｢$repo｣ can not install!];

    $repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation ).first( *.can-install );

    🐞 qq[REP: ｢$repo｣ will be used!] if $repo ;

    die X::Pakku::Add.new: dist => $path unless $repo;

  }

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self.build: :$dist if $build;

      🦋 qq[STG: ｢$dist｣];

      $*stage.install: $dist, :$precompile;

      self.test: :$dist :$xtest if $test;

    } );

  $*stage.remove-artifacts;

  unless self!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

      🐛 qq[BIN: ｢{ $repo.prefix.add( 'bin' ) }｣ binaries added!] if @bin;

      @bin.map( -> $bin { 🧚 qq[BIN: ｢{ $bin.IO.basename }｣] } ).eager;

    }
  }
   
}

