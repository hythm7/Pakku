use JSON::Fast;
use LibCurl::Easy;

use Pakku::Dist;


unit class Pakku::RecMan;

has @.source;
has %!ecosystem;

submethod TWEAK ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    
    for flat $json -> %meta {
      %!ecosystem.push: ( %meta<name> => %meta ); 
    }
  }
}

method search ( :@ident! ) {
  
    for @ident -> $ident {
      say %!ecosystem{$ident<name>};
    }
}


