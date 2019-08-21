use Pakku::Dist;
use Pakku::Ecosystem;
use Pakku::Identity;


unit class Pakku::RecMan;

has Pakku::Ecosystem $.ecosystem;

method recommend ( :@ident! ) {
  # should return modules as well

  my @*cand;

  for @ident -> $ident {
    given $ident {

      when Pakku::Identity {

        @*cand.push: $!ecosystem.find( $ident ).first.<source-url>;

      }

      when IO::Path {

        @*cand.push: $ident;

      }
    }
  }

  @*cand;
}
