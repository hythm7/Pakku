use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::State;

multi method fly (

    'state',

    :$clean   = False,
    :$updates = True,

    :@spec = self!repo.map( *.installed ).flat.grep( *.defined ).map( { Pakku::Meta.new( .meta ).Str } )

  ) {

  🧚 qq[STT: ｢...｣];

  my %state = self.state: :$updates;

  %state.values
    ==> grep( *.<cln> )
    ==> map( *.<meta> )
    ==> my @clean;

  sink @spec.sort
    ==> map( -> $spec { Pakku::Spec.new: $spec } )
    ==> map( -> $spec { 
        
      🐛 "STT: ｢$spec｣";

      self!repo
        ==> map( -> $repo { $repo.candidates( $spec.name , |$spec.spec ) } )
        ==> flat( )
        ==> grep( *.defined )
        ==> my @candy;

      unless @candy {

        🐞 "SPC: ｢$spec｣ not added!";

        next;
      }

      sink @candy.map( -> $spec {

        🐛 "SPC: ｢$spec｣";

        my $state = %state{ $spec };

        unless $state {

          🐞 "SPC: ｢$spec｣ not added!";

          next;

        }

        my @dep      = $state.<dep>.grep( Pakku::Meta       ).grep( *.defined );
        my @missing  = $state.<dep>.grep( Pakku::Spec::Raku ).grep( *.defined );

        my @rev     = $state.<rev>.grep( *.defined );
        my @upd = $state.<upd>.grep( *.defined );

        @dep.map( -> $meta { 🐛 "DEP: ｢$meta｣" } );

        @missing.map( -> $spec { 🐞 "DEP: ｢$spec｣ missing!"  } );

        @upd.map( -> $meta { 🦋 "UPD: ｢$meta｣" } );

        @rev.map( -> $meta { 🐛 "REV: ｢$meta｣"  } );

        🦗 "STT: ｢$spec｣" if     @missing;
        🧚 "STT: ｢$spec｣" unless @missing;

        sink @clean
          ==> grep( -> $meta { $spec ~~ $meta.dist } )
          ==> map( -> $meta {

            🦋 "CLN: ｢$spec｣";

            unless self!dont {
              samewith 'remove', spec => $meta.dist.Array if $clean;
            }

          } );
      } );
    } );
}

