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
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
         :$to         = 'site',
         :$exclude,

) {

  🧚 PRC ~ "｢{@spec}｣";

  my $*repo = Pakku::Repo.new: $to; 

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

  @meta
    ==> map( -> $meta {

      my $prefix = $.fetch: :$meta;

      $meta.to-dist: :$prefix;

    } )
    ==> my @dist;

  my $target = CompUnit::RepositoryRegistry.repository-for-name: $to ~~ Str ?? $to !! 'custom';

  $target.upgrade-repository unless $target.prefix.add( 'version' ).e;

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage,
    name      => $target.name,
    next-repo => $target;

  try $*stage.self-destruct;

  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist, :$precompile;

      self!test: :$dist if $test;

    } );

  $*stage.remove-artifacts;

  unless $!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      🧚 BIN ~ "｢{.IO.basename}｣" for Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

    }
  }
   
  try $*stage.self-destruct;
  
  ofun;

}

method upgrade (

         :@spec!,
         :$deps   = True,
  Bool:D :$build  = True,
  Bool:D :$test   = True,
  Bool:D :$force  = False,
         :$in     = 'site',
         :$exclude,

) {

  🧚 PRC ~ "｢{@spec}｣";

  my $*repo = Pakku::Repo.new: $in;

  @spec .= map(  -> $spec { self.upgradable: spec => Pakku::Spec.new: $spec } );

  return ofun unless so @spec;

  @spec .= map( *.Str );

  self.add: :@spec :$deps :$build :$test :$force :$exclude :to( $in );

}

method test ( :$spec!, Bool:D :$build = True ) {

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage,
    name      => 'stage',
    next-repo => CompUnit::RepositoryRegistry.repository-for-name: 'home';

  try $*stage.self-destruct;

  my $meta = self.satisfy: spec => Spec.new: $spec;
  my $dist = $meta.to-dist: prefix => $.fetch: :$meta;

  self!build: :$dist if $build;

  🦋 STG ~ "｢$dist｣";

  $*stage.install: $dist;

  self!test: :$dist unless $!dont;

  try $*stage.self-destruct;

  ofun;

}

method build ( :$spec! ) {

  my $meta = self.satisfy: spec => Spec.new: $spec;

  my $dist = $meta.to-dist: prefix => $.fetch: :$meta;

  my $*stage := CompUnit::RepositoryRegistry.repository-for-spec: $dist.prefix.add( 'lib' ).Str;

  self!build: :$dist unless $!dont;

  ofun;

}

method remove ( :@spec!, :$from ) {

  my $repo = Pakku::Repo.new: $from;

  @spec.map( -> $spec { sink $repo.remove: :$from, spec => Spec.new: $spec } ) unless $!dont;

  ofun;

}

method list (

         :@spec,
  Bool:D :$details = False,
         :repo( $name ),

) {

  my $repo = Pakku::Repo.new: $name;

  @spec 
    ??  ( $repo.list( spec => @spec.map( -> $spec { Spec.new: $spec } ) )
          ==> map( -> $meta { out Meta.new( $meta ).gist: :$details } ) )
    !!  ( $repo.list
          ==> map( -> $meta { out Meta.new( $meta ).gist: :$details } ) ) unless $!dont;

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

method checkout ( :@spec! ) {

  @spec
    ==> map( -> $spec { Spec.new:      $spec               } )
    ==> map( -> $spec { self.satisfy: :$spec               } )
    ==> map( -> $meta { self.fetch:   :$meta unless $!dont } )
    ==> map( -> $path { 🧚 "CHK: ｢$path｣"                  } );

  ofun;

}
