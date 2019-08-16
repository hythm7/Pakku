use JSON::Fast;
use LibCurl::Easy;


unit class Pakku::RecMan;

has @.source;
has %!ecosystem;

submethod TWEAK ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    
    for flat $json -> %dist {
      %!ecosystem.push: ( %dist<name> => %dist ); 
    }
  }
}

method search ( :@dist! ) {
  
    for @dist -> $dist {
      .say for %!ecosystem{$dist};
    }
}


