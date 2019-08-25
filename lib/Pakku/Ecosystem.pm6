use JSON::Fast;
use LibCurl::Easy;

use Pakku::Specification;
use Pakku::Distribution;

unit class Pakku::Ecosystem;

has @.source;
has %!distribution;
has @!distribution;

submethod TWEAK ( ) {

  self!update;

}

method recommend ( :@spec! ) {

  my @*cand;

  for @spec -> $spec {

    given $spec {

      when Pakku::Specification {

        my $dist = self!search: :$spec;

        @*cand.push: $dist if $dist;

      }

      when IO::Path {

        my $meta = $spec.add: 'META6.json';

        die 'No META6.json' unless $meta.e;

        my %meta = from-json slurp $meta;

        my $dist = Pakku::Distribution.new: |%meta;

        $dist.prefix = $spec;

        @*cand.push: $dist if $dist;

      }

      default { die "I don't understand $spec" }
    }
  }

  @*cand;
}

method !search ( Pakku::Specification:D :$spec! --> Pakku::Distribution ) {

  my @cand;

  my $name = $spec.short-name;

  @cand = flat %!distribution{$name} if so %!distribution{$name};


  @cand = @!distribution.grep: *.provides: :$name unless @cand;

  @cand.grep( * ~~ $spec ).sort( *.version ).tail;

}

method !update ( ) {

  for @!source -> $source {

    #my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    my $json = from-json slurp %?RESOURCES<cpan.json>;

    for flat $json -> %meta {

      my $dist = Pakku::Distribution.new: :%meta;

      %!distribution{ $dist.name }.push: $dist;
      @!distribution.push: $dist;
    }
  }

}

