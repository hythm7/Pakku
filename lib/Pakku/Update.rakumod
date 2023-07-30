use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::State;

unit role Pakku::Update;

multi method fly (

         'update',
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
  Bool:D :$clean      = True,
  Str:D  :$in         = 'site',
         :@exclude,

    :@spec = self!repo.map( *.installed ).flat.grep( *.defined ).map( { Pakku::Meta.new( .meta ).Str } )

  ) {

  🧚 "UPD: ｢...｣";

  my @add;

  my %state = Pakku::State.new( recman => self!recman ).state;

  sink @spec.sort
   ==> map( -> $spec { Pakku::Spec.new: $spec } )
   ==> map( -> $spec {

     🐛 "SPC: ｢$spec｣";

     self!repo
       ==> map( -> $repo { $repo.candidates( $spec.name , |$spec.spec ) } )
       ==> flat( )
       ==> grep( *.defined )
       ==> grep( *.Str )
       ==> my @candy;

     unless @candy {

       🐞 "SPC: ｢$spec｣ not added!";

       next;

     }

     sink @candy.map( -> $spec {
    
       my $state = %state{ $spec };

       my $upd = $state.<upd>.grep( *.defined ).head;

       unless $upd {

         🐛 "UPD: ｢$spec｣ no updates!";

         next;

       }

       🦋 "UPD: ｢$upd｣";

       @add.push: $upd;

     } );

   } );


  my @repo = self!repo;

  self!repo = CompUnit::RepositoryRegistry.repository-for-name('core');

  🧚 qq[UPD: ｢{ @add }｣] if @add;

  @add 
    ==> unique( as => *.Str )
    ==> map(  -> $meta {

      my @meta = flat self.get-deps: $meta, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );
      @meta .= unique( as => *.Str );

      @meta.append: $meta unless $deps ~~ <only>;

      @meta;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  self!repo = @repo;

  @meta
    ==> grep( -> $meta { not self.satisfied: spec => Pakku::Spec.new: ~$meta } )
    ==> map( -> $meta {

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

    } )
  ==> my @dist;


  my $repo = self.repo-from-spec: spec => $in;

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

    if $clean {

      my @clean = Pakku::State.new( recman => self!recman, :!updates ).cleanable;

      samewith 'remove', spec => @clean.map( *.Str ) if @clean;
    }

  }

}
