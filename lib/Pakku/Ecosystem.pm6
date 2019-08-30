use JSON::Fast;
use LibCurl::Easy;

use Pakku::Specification;
use Pakku::Distribution;

unit class Pakku::Ecosystem;

has @.source;
has @!ignored;
has %!distribution;
has @!distribution;

submethod TWEAK ( ) {

  @!ignored = < Test NativeCall nqp lib >;
  self!update;

}

method recommend ( :@spec!, :$deps = True ) {


  @spec.map( -> $spec {

    my $dist = self!find: :$spec;

    $deps ?? self.get-deps: :$dist !! $dist;

  });

}


method get-deps ( Pakku::Distribution :$dist ) {

  my @dist;

  my @dep = $dist.dependencies.map( -> $spec {

    next if $spec.name ~~ any @!ignored;

    self!find: :$spec or die "Can't find dep $spec"

  });

  for @dep -> $dist {

    @dist.append: self.get-deps( :$dist );

  }

  @dist.append: $dist;

  return @dist;

}

method !find ( Pakku::Specification:D :$spec! --> Pakku::Distribution ) {

  my @cand;

  my $name = $spec.short-name;

  @cand = flat %!distribution{$name} if so %!distribution{$name};

  @cand = @!distribution.grep: *.provides: :$name unless @cand;

  @cand.grep( * ~~ $spec ).sort( *.version ).tail;

}

method !update ( ) {

  for @!source -> $source {

    my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    #my $json = from-json slurp %?RESOURCES<cpan.json>;

    for flat $json -> %meta {

      my $dist = Pakku::Distribution.new: :%meta;

      %!distribution{ $dist.name }.push: $dist;
      @!distribution.push: $dist;
    }
  }
}

