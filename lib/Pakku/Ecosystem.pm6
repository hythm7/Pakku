use JSON::Fast;
use LibCurl::Easy;

use Pakku::Distribution;

unit class Pakku::Ecosystem;

has @.source;
has %!project;

submethod TWEAK ( ) {

  self!update;

}

method recommend ( :@spec! ) {
  # should return modules as well

  my @*cand;

  for @spec -> $spec {
    
    given $spec {

      when CompUnit::DependencySpecification {

        my $dist = %!project{$spec.short-name}.first;

        @*cand.push: $dist;
  
      }

      when IO::Path {

        my $meta = $spec.add: 'META6.json';

        die 'No META6.json' unless $meta.e;

        my %meta = from-json slurp $meta;

        my $dist = Pakku::Distribution.new: |%meta;

        $dist.source-path = $spec;

        @*cand.push: $dist;

      }
    }
  }

  @*cand;
}

method !update ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;

    for flat $json -> %meta {
      %!project{ %meta<name> }.push: Pakku::Distribution.new: |%meta;
    }
  }

}

