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

      my $prefix = $.fetch: :$meta;
    
      $meta.to-dist: :$prefix;

    } )
    ==> my @dist;

   
  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      self!test:  :$dist if $test;
  
      unless $!dont {

        🐞 "ADD: ｢$dist｣";

        $*repo.add: :$dist :$force;

        $dist.meta<files>
          ==> keys( )
          ==> categorize( *.IO.dirname )
          ==> my %files;

        my @bin = .flat with %files<bin>;
        my @res = .flat with %files<resources>;

        @bin
          ==> map( -> $bin { 🦋 "BIN: ｢{ $*repo.prefix }/$bin｣" } );

        @res
          ==> map( -> $res { 🦋 "RES: ｢$res｣" } );

        🦋 "ADD: ｢$dist｣";

      }
  
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
    ==> map( -> $meta { 🦋 Meta.new( $meta ).gist: :$details } ) unless $!dont;

  return;

}

method search (

         :@spec,
         :$count   = ∞,
  Bool:D :$details = False,

) {

  @spec
    ==> map( -> $spec { Spec.new: $spec                        } )
    ==> map( -> $spec { $!recman.search( :$spec :$count ).Slip } )
    ==> map( -> $meta { Meta.new( $meta ).gist: :$details      } )
    ==> map( -> $meta { 🦋 $meta                               } );

  return;

}


method build ( :@spec! ) {

  my $*repo = Pakku::Repo.new;

  @spec
    ==> map( -> $spec { Spec.new: $spec                          } )
    ==> map( -> $spec { self.satisfy: :$spec                     } )
    ==> map( -> $meta { $meta.to-dist: prefix => $.fetch: :$meta } )
    ==> map( -> $dist { self!build: :$dist unless $!dont         } );

  return;

}

method test ( :@spec! ) {

  my $*repo = Pakku::Repo.new;

  @spec
    ==> map( -> $spec { Spec.new: $spec                          } )
    ==> map( -> $spec { self.satisfy: :$spec                     } )
    ==> map( -> $meta { $meta.to-dist: prefix => $.fetch: :$meta } )
    ==> map( -> $dist { self!test: :$dist unless $!dont          } );

  return;

}

method checkout ( :@spec! ) {

  @spec
      ==> map( -> $spec { Spec.new: $spec               } )
      ==> map( -> $spec { self.satisfy: :$spec          } )
      ==> map( -> $meta { $.fetch: :$meta unless $!dont } )
      ==> map( -> $path { 🦋 "CHK: ｢$path｣"             } );

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
