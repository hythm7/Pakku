use JSON::Fast;
use LibCurl::Easy;

use Pakku::Dist;
use Pakku::Identity;


unit class Pakku::RecMan;

has @.source;
has %!ecosystem;

method recommend ( :@dist! ) {
  
  my @*cand;

  for @dist -> $dist {
    given $dist {
      
      when Pakku::Identity {
        
        self!update;

        @*cand.push: %!ecosystem{$dist.name}.first;
      
      }
      
      when IO::Path {

        my $json = from-json slurp $dist.add: 'META6.json';

        $json<source-url> = $dist;
        
        @*cand.push: $json;

      }
      
    }
  }

  @*cand;
}

method !update ( ) {
  
  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;

    for flat $json -> %meta {
      %!ecosystem.push: ( %meta<name> => %meta ); 
    }
  }


}


