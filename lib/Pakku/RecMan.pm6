use JSON::Fast;
use LibCurl::Easy;

use Pakku::Dist;
use Pakku::Identity;


unit class Pakku::RecMan;

has @.source;
has %!ecosystem;

submethod TWEAK ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    
    for flat $json -> %meta {
      %!ecosystem.push: ( %meta<name> => Pakku::Dist.new: |%meta ); 
    }
  }
}

method search ( :@ident! ) {
  
  my @cand;

  for @ident -> $ident {
    @cand.push: %!ecosystem{$ident.name};
  }

  @cand;
}


