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

  my %state = self.state: :$updates;

  %state.values
    ==> grep( *.<cln> )
    ==> map( *.<meta> )
    ==> my @clean;

  sink @spec.sort
    ==> map( -> $spec { Pakku::Spec.new: $spec } )
    ==> map( -> $spec { 
        
      log '🐛', header => 'STT', msg => ~$spec;

      self!repo
        ==> map( -> $repo { $repo.candidates( $spec.dependency-specification ) } )
        ==> flat( )
        ==> grep( *.defined )
        ==> map( *.Str )
        ==> my @candy;

      unless @candy {

        log '🐞', header => 'SPC', msg => ~$spec, comment => 'not added!';

        next;
      }

      eager @candy.map( -> $spec {

        log '🐛', header => 'SPC', msg => ~$spec;

        my $state = %state{ $spec };

        unless $state {

          log '🐞', header => 'SPC', msg => ~$spec, comment => 'not added!';

          next;

        }

        my @dep      = $state.<dep>.grep( Pakku::Meta       ).grep( *.defined );
        my @missing  = $state.<dep>.grep( Pakku::Spec::Raku ).grep( *.defined );

        my @rev     = $state.<rev>.grep( *.defined );
        my @upd = $state.<upd>.grep( *.defined );

        @dep.map( -> $meta { log '🐛', header => 'DEP', msg => ~$meta} );

        @missing.map( -> $spec { log '🐞', header => 'DEP', msg => ~$spec, comment => 'missing!' } );

        @upd.map( -> $meta { log '🦋', header => 'UPD', msg => ~$meta; } );

        @rev.map( -> $meta { log '🐛', header => 'REV', msg => ~$meta } );

        log '🦗',  header => 'STT', msg => ~$spec if     @missing;
        log '🧚',  header => 'STT', msg => ~$spec unless @missing;

        eager @clean
          ==> grep( -> $meta { $spec ~~ $meta.dist } )
          ==> map( -> $meta {

            log '🦋', header => 'CLN', msg => ~$spec;

            unless self!dont {
              samewith 'remove', spec => $meta.dist.Array if $clean;
            }

          } );
      } );
    } );
}

