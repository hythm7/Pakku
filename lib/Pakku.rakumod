use Pakku::Log;
use Pakku::Guts;

unit class Pakku;
  also does Pakku::Guts;


method add (

         :@spec!,
         :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,
         :$repo,

) {

  🦋 "PRC: ｢{@spec}｣";

  my $*repo = Pakku::Repo.new: :$repo;

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

      my $prefix = $.fetch: $meta.recman-src;
    
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
    
    
  return;

}

method remove (

  :@spec!,
  :$repo,

) {

  my $*repo = Pakku::Repo.new: :$repo;

  @spec.map( -> $spec {

    sink $*repo.remove: spec => Spec.new: $spec unless $!dont;

  } );

  return;

}


method list (

         :@spec,
  Bool:D :$details = False,
         :$repo,

) {

  my $*repo = Pakku::Repo.new: :$repo;

  @spec .= map( -> $spec { Spec.new: $spec } );

  $*repo.list: :@spec
    ==> map( -> $meta { Meta.new( $meta ).gist: :$details } )
    ==> map( -> $meta { 🦋 $meta } ) unless $!dont;

  return;

}

method search (

         :@spec,
         :$count   = ∞,
  Bool:D :$details = False,

) {

  @spec
    ==> map( -> $spec { Spec.new: $spec } )
    ==> map( -> $spec { $!recman.search( :$spec :$count ).Slip } )
    ==> map( -> $meta { Meta.new( $meta ).gist: :$details } )
    ==> map( -> $meta { 🦋 $meta } );

  return;

}


method build ( :@spec! ) {

  my $*repo = Pakku::Repo.new;

  @spec
    ==> map( -> $spec { Spec.new: $spec } )
    ==> map( -> $spec { self.satisfy: :$spec } )
     ==> map( -> $meta { $meta.to-dist: prefix => $.fetch: $meta.recman-src } )
    ==> map( -> $dist { $!builder.build: :$dist unless $!dont } );

  return;

}

method test ( :@spec! ) {

  my $*repo = Pakku::Repo.new;

  @spec
    ==> map( -> $spec { Spec.new: $spec } )
    ==> map( -> $spec { self.satisfy: :$spec } )
    ==> map( -> $meta { $meta.to-dist: prefix => $.fetch: $meta.recman-src } )
    ==> map( -> $dist { $!tester.test: :$dist unless $!dont } );

  return;

}

method checkout ( :@spec! ) {

  @spec
      ==> map( -> $spec { Spec.new: $spec } )
      ==> map( -> $spec { self.satisfy: :$spec } )
      ==> map( -> $meta { $.fetch: $meta.recman-src, :!unlink unless $!dont } )
      ==> map( -> $path { 🦋 "CHK: ｢$path｣" } );

  return;

}

method pack (

  :@spec!,
  *%args,

) {

  🦋 "PAC: ｢{@spec}｣";

  my $rakudo = $.pakudo: |%args unless $!dont;

  my $repo = .add: 'share/perl6/site' with $rakudo;

  $.add: :@spec, :$repo, |%args;

  🦋 "PAC: ｢$rakudo｣" unless $!dont;

  return;
}
