use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit class Pakku::State;

has %.state;
has $!recman;

has @.ok;
has @.error;
has @.updatable;
has @.cleanable;

submethod BUILD ( :$!recman, :$updates = True ) {

  🐛 "STT: ｢...｣";

  my @repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );

  @repo
    ==> map( *.installed )
    ==> grep( *.defined )
    ==> flat(  )
    ==> map( { Pakku::Meta.new: .meta } )
    ==> map( -> $meta { 

      🐛 "STT: ｢$meta｣";

      unless %!state{ $meta }:exists {

        %!state{ $meta }.<dep> = [];
        %!state{ $meta }.<rev> = [];
        %!state{ $meta }.<upd> = [];

      }

      %!state{ $meta }.<meta> = $meta;

      $!recman.search( :spec( Pakku::Spec.new: $meta.name ) :!relaxed :42count )
        ==> grep( *.defined )
        ==> grep( -> %meta { $meta.name       ~~ %meta.<name> } )
        ==> grep( -> %meta { $meta.meta<auth> ~~ %meta.<auth> } )
        ==> grep( -> %meta {
              ( quietly Version.new( %meta<version> ) cmp Version.new( $meta.meta<version> ) or  
                quietly Version.new( %meta<api>     ) cmp Version.new( $meta.meta<api>     )  
              ) ~~ More
            } )
        ==> sort( &sort-latest )
        ==> map( -> %meta { Pakku::Meta.new: %meta } )
        ==> my @upd if $updates and $!recman;

      if @upd {
        %!state{ $meta  }.<upd> .append: @upd;
        @!updatable.push( $meta ) unless @!updatable.grep( $meta );
      }

      sink $meta.deps( :deps ).grep( Pakku::Spec::Raku ).grep( *.name.so ).map( -> $spec {

        🐛 "SPC: ｢$spec｣";

        @repo
          ==> map( -> $repo { $repo.candidates( $spec.name , |$spec.spec ).head } )
          ==> grep( *.defined )
          ==> my @candy;

        my $candy = @candy.head;

        unless $candy {

          🐛 "SPC: ｢$spec｣ missing!";

          %!state{ $meta }.<dep> .push: $spec;

          @!error.push( $meta ) unless @!error.grep( $meta );

          next;
        }

        my $dep = Pakku::Meta.new: $candy.read-dist( )( $candy.id );

        🐛 "DEP: ｢$dep｣";

        %!state{ $meta }.<dep> .push: $dep;
        %!state{ $dep  }.<rev> .push: $meta;

      } );

      @!ok.push( $meta ) unless @!ok.grep( $meta );
  } );

  my %meta;

  %!state.values
    ==> map( *.<meta> )
    ==> map( -> $meta { %meta{ $meta.name }.push: $meta } );

  %!state.values
    ==> grep( *.<rev>.not )
    ==> map( *.<meta> )
    ==> grep( -> $meta {
       any %meta{ $meta.name }.map( {
         ( quietly Version.new( $meta.meta.<version> ) cmp Version.new( .meta<version> ) or  
           quietly Version.new( $meta.meta.<api>     ) cmp Version.new( .meta<api>     )  
         ) ~~ Less
       } ) 
    } )
    ==> @!cleanable;
}


my sub sort-latest ( %left, %right ) {

  quietly ( Version.new( %right<version> ) cmp Version.new( %left<version> ) ) or 
  quietly ( Version.new( %right<api> ) cmp Version.new( %left<api> ) );

}
