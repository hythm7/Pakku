use Pakku::Log;
use Pakku::Guts;

unit class Pakku:ver<pupa>:auth<github:hythm7>;
  also does Pakku::Guts;


method add (

         :@spec!,
         :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {

  🦋 "PRC: ｢{@spec}｣";

  @spec

    ==> map( -> $spec { Spec.new: $spec } )

    ==> grep( -> $spec { $force or not self.satisfied: :$spec } )

    ==> unique( as => *.Str )

    ==> map( -> $spec { self.satisfy: :$spec } )

    ==> map( -> $dep {

      my @dep = self.get-deps( $dep, :$deps );

      @dep.append: $dep unless $deps ~~ <only>;

      @dep;

    } )

    ==> flat( )

    ==> unique( as => *.Str )

    ==> my @meta;


  @meta

    ==> map( -> $meta {

      my $prefix = $!fetcher.fetch: $meta.source;
    
      $meta.to-dist: :$prefix;

    } )

    ==> my @dist;

   
  @dist 

    ==> map( -> $dist {
  
      $!builder.build: :$dist if $build;

      $!tester.test:   :$dist if $test;
  
      $*repo.add: :$dist, :$force     unless $!dont;

      🦋 "ADD: ｢$dist｣" unless $!dont;
  
    } );
    
    
  ofun;

}

method remove ( :@spec! ) {

  @spec.map( -> $spec {

    sink $*repo.remove: spec => Spec.new: $spec unless $!dont;

  } );

  ofun;

}

method list (

  :@spec,

  Bool:D :$details = False,
  Bool:D :$remote  = False,
  Bool:D :$local   = !$remote,

) {

  @spec .= map( -> $spec { Spec.new: $spec } );

  $local ?? $*repo.list: :@spec !! $!recman.list: :@spec
    ==> map( -> $meta { Meta.new( $meta ).gist: :$details } )
    ==> map( -> $meta { 🦋 $meta } );

  ofun;

}

method build ( :@spec! ) {

  @spec
    ==> map( -> $spec { Spec.new: $spec } )
    ==> map( -> $spec { self.satisfy: :$spec } )
    ==> map( -> $meta { $meta.to-dist: prefix => $!fetcher.fetch: $meta.source } )
    ==> map( -> $dist { $!builder.build: :$dist unless $!dont } );


  ofun;

}

method test ( :@spec! ) {

  @spec
    ==> map( -> $spec { Spec.new: $spec } )
    ==> map( -> $spec { self.satisfy: :$spec } )
    ==> map( -> $meta { $meta.to-dist: prefix => $!fetcher.fetch: $meta.source } )
    ==> map( -> $dist { $!tester.test: :$dist unless $!dont } );


  ofun;

}

method check ( :@spec! ) {

  @spec
      ==> map( -> $spec { Spec.new: $spec } )
      ==> map( -> $spec { self.satisfy: :$spec } )
      ==> map( -> $meta { $!fetcher.fetch: $meta.source, :!unlink unless $!dont } )
      ==> map( -> $path { 🦋 "CHK: ｢$path｣" } );


  ofun;

}

