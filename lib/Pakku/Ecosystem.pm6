use JSON::Fast;
use LibCurl::Easy;

unit class Pakku::Ecosystem;

has @.source;
has %!project;

submethod TWEAK ( ) {

  self!update;

}

method find ( $dist ) {

  %!project{$dist.name};

}

method !update ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;

    for flat $json -> $meta {
      %!project{ $meta<name> }.push: $meta;
    }
  }


}

