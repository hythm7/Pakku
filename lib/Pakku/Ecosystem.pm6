use JSON::Fast;
use LibCurl::HTTP :subs;

use X::Pakku;
use Pakku::Spec;
use Pakku::Dist;

unit class Pakku::Ecosystem;

has $.log;
has @.source;
has @!ignored;
has %!dist;
has @!dist;

submethod TWEAK ( ) {

  @!ignored = < Test NativeCall nqp lib >;
  self!update;

}

method recommend ( :@spec!, :$deps! --> Seq ) {


  $!log.debug: "Looking for {@spec}";

  @spec.map( -> $spec {

    my $dist = self!find: :$spec;

    $deps ?? self.get-deps: :$dist !! $dist.Seq;

  });

}


method get-deps ( Pakku::Dist:$dist ) {

  my @dist;

  my @dep = $dist.dependencies.map( -> $spec {

    next if $spec.name ~~ any @!ignored;

    my $candy = self!find: :$spec;


    $candy;

  });

  for @dep -> $dist {

    @dist.append: self.get-deps( :$dist );

  }

  @dist.append: $dist;

  return @dist;

}

method !find ( Pakku::Spec:D :$spec! ) {

  my @cand;

  my $name = $spec.short-name;

  @cand = flat %!dist{$name} if so %!dist{$name};

  @cand = @!dist.grep: *.provides: :$name unless @cand;

  my $candy = @cand.grep( * ~~ $spec ).sort( *.version ).tail;

  $!log.fatal: "No candies for $spec" unless $candy;

  $candy;

}

method !update ( ) {

  for @!source -> $source {

    #my $json = from-json LibCurl::Easy.new( URL => $source ).perform.content;
    my $json = from-json slurp %?RESOURCES<ecosystem.json>;

    #my $json =  jget $source;


    for flat $json -> %meta {

      my $dist = Pakku::Dist.new: :%meta;

      %!dist{ $dist.name }.push: $dist;
      @!dist.push: $dist;
    }
  }
}

