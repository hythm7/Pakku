use Pakku::Dist;
use Pakku::Identity;


unit class Pakku::RecMan;

has $.ecosystem;

method recommend ( :@dist! ) {
  
  my @*cand;

  for @dist -> $dist {
    given $dist {
      
      when Pakku::Identity {
        
        @*cand.push: $!ecosystem.find( $dist ).first;
      
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
