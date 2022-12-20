use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Core;

unit class Pakku;
  also does Pakku::Core;

method add (

         :@spec!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
         :$exclude,

  CompUnit::Repository:D :$repo = CompUnit::RepositoryRegistry.repository-for-name( 'site' ),

) {

  🧚 PRC ~ "｢{@spec}｣";


  @spec
    ==> map(  -> $spec { Spec.new: $spec } )
    ==> grep( -> $spec { $force or not self.satisfied: :$spec } )
    ==> unique( as => *.Str )
    ==> map(  -> $spec { self.satisfy: :$spec } )
    ==> map(  -> $dep {

      my @dep = self.get-deps: $dep, :$deps, |( exclude => Spec.new( $exclude )  if $exclude );

      @dep.append: $dep unless $deps ~~ <only>;

      @dep;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  @meta.hyper( degree => $!cores )
    ==> map( -> $meta {

      my $prefix = $.fetch: :$meta;

      $meta.to-dist: :$prefix;

    } )
    ==> my @dist;

  #my $target = CompUnit::RepositoryRegistry.repository-for-name: $to.name ~~ Str ?? $to !! 'custom';

  #$target.upgrade-repository unless $target.prefix.add( 'version' ).e;

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage,
    name      => $repo.name // 'custom',
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist, :$precompile;

      self!test: :$dist :$xtest if $test;

    } );

  $*stage.remove-artifacts;

  unless $!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      🧚 BIN ~ "｢{.IO.basename}｣" for Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

    }
  }
   
  
  ofun;

}

method upgrade (

         :@spec!,
         :$deps   = True,
  Bool:D :$build  = True,
  Bool:D :$test   = True,
  Bool:D :$xtest  = False,
  Bool:D :$force  = False,
         :$exclude,

  CompUnit::Repository:D :$repo = CompUnit::RepositoryRegistry.repository-for-name( 'site' ),

) {

  🧚 PRC ~ "｢{@spec}｣";

  @spec .= map(  -> $spec { self.upgradable: spec => Pakku::Spec.new: $spec } );

  return ofun unless so @spec;

  @spec .= map( *.Str );

  self.add: :@spec :$deps :$build :$test :$force :$exclude :$repo;

}

method test ( :$spec!, Bool:D :$xtest  = False, Bool:D :$build = True ) {
  

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage,
    name      => 'home',
    next-repo => $*REPO;


  my $meta = self.satisfy: spec => Spec.new: $spec;
  my $dist = $meta.to-dist: prefix => $.fetch: :$meta;

  self!build: :$dist :$xtest if $build;

  🦋 STG ~ "｢$dist｣";

  $*stage.install: $dist;

  self!test: :$dist :$xtest unless $!dont;

  ofun;

}

method build ( :$spec! ) {

  my $meta = self.satisfy: spec => Spec.new: $spec;

  my $dist = $meta.to-dist: prefix => $.fetch: :$meta;

  my $*stage := CompUnit::RepositoryRegistry.repository-for-spec: $dist.prefix.add( 'lib' ).Str;

  self!build: :$dist unless $!dont;

  ofun;

}

method remove ( :@spec!, CompUnit::Repository :$repo ) {

	@!repo
	  ==> grep( $repo )
		==> map( -> $repo {
		  sink @spec.map( -> $str {
				my $spec = Pakku::Spec.new: $str;
				my @dist = $repo.candidates( $spec.name, |$spec.spec );

				sink @dist.map( -> $dist { $repo.uninstall: $dist } )

			} ) unless $!dont
		} );

  ofun;

}

method list ( :@spec, CompUnit::Repository :$repo, Bool:D :$details = False ) {

	if @spec {
	  
		@spec .= map( -> $spec { Pakku::Spec.new: $spec } );

    @spec.map( -> $spec {

			@!repo
				==> grep( $repo )
				==> map( -> $repo {
					$repo.candidates( $spec.name, |$spec.spec )
						==> map( -> $dist { $dist.id } )
						==> map( -> $id   { $repo.distribution: $id } )
						==> map( -> $dist { $dist.meta.item } )
						==> flat( );
					} )
				==> flat( );
    } )
    ==> flat( )
		==> map( -> $meta { Meta.new: $meta } )
		==> map( -> $meta { out $meta.gist: :$details } );


	} else {

	@!repo
	  ==> grep( $repo )
		==> map( *.installed.map( *.meta.item ) )
		==> flat( )
		==> grep( *.defined )
		==> map( -> $meta { Meta.new: $meta } )
		==> map( -> $meta { out $meta.gist: :$details } );
	}

  return;

}

method search (

         :@spec,
  Int    :$count,
  Bool:D :$details = False,

) {

  @spec
    ==> map( -> $spec { Spec.new: $spec                        } )
    ==> map( -> $spec { $!recman.search( :$spec :$count ).Slip } )
    ==> map( -> $meta { Meta.new( $meta ).gist: :$details      } )
    ==> map( -> $meta { out $meta                              } );

  return;

}

method download ( :@spec! ) {

  @spec
    ==> map( -> $spec { Spec.new:      $spec               } )
    ==> map( -> $spec { self.satisfy: :$spec               } )
    ==> map( -> $meta { self.fetch:   :$meta unless $!dont } )
    ==> map( -> $path { 🧚 "DWN: ｢$path｣"                  } );

  ofun;

}
