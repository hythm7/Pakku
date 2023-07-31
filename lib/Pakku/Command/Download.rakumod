use Pakku::Log;
use Pakku::Spec;

unit role Pakku::Command::Download;

multi method fly ( 'download', :@spec! ) {

  🧚 "DWN: ｢{@spec}｣";

  sink @spec
    ==> map( -> $spec { Pakku::Spec.new:      $spec               } )
    ==> map( -> $spec { self.satisfy: :$spec               } )
    ==> map( -> $meta {

        🦋 qq[FTC: ｢$meta｣];

        my IO::Path $path = $*TMPDIR.add( $meta.id ).add( now.Num );

        my $cached = self!cache.cached( :$meta ) if self!cache;

        if $cached {

          self.copy-dir: src => $cached, dst => $path unless self!dont;

        } else {

          my $src = $meta.source;

          self.fetch: src => $meta.source, dst => $path unless self!dont;

          self!cache.cache: :$path if self!cache;
        }

        🧚 "DWN: ｢$path｣" unless self!dont;

      } );
}
