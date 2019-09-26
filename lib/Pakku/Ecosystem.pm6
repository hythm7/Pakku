use JSON::Fast;
use LibCurl::HTTP :subs;

use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Dist;

unit class Pakku::Ecosystem;

has @.source;
has @!ignored;
has %!dist;
has @!dist;

submethod TWEAK ( ) {

  @!ignored = < Test NativeCall nqp lib >;
  self!update;

}

method recommend ( :@spec!, :$deps! --> Seq ) {


  🐛 "Eco: Processing specs [{@spec}]";

  @spec.map( -> $spec {

    my $dist = self!find: :$spec;

    $deps ?? self!get-deps: :$dist !! $dist.Seq;

  }).map( *.unique: :with( &[===] ) );

}


submethod !get-deps ( Pakku::Dist:D :$dist! ) {

  🐛 "Eco: Looking for deps of dist [$dist]";

  my @dist;

  my @dep = $dist.deps;

  🐛 "Eco: Found no deps for [$dist]" unless @dep;

  @dep .= map( -> $spec {

    if $spec.name ~~ any @!ignored {

      🐛 "Eco: Ignoring Core spec [$spec]";

      next;
    }


    🐛 "Eco: Found dep [$spec] for dist [$dist]";

    self!find: :$spec;

  });

  for @dep -> $dist {

    @dist.append: self!get-deps( :$dist );

  }

  @dist.append: $dist;

  return @dist;

}

submethod !find ( Pakku::Spec:D :$spec! ) {

  🐛 "Eco: Looking for spec [$spec]";

  my @cand;

  my $name = $spec.short-name;

  @cand = flat %!dist{$name} if so %!dist{$name};

  @cand = @!dist.grep( -> $dist { $name ~~ $dist.provides } ) unless @cand;

  @cand .= grep( * ~~ $spec );

  unless @cand {

    die X::Pakku::Ecosystem::NoCandy.new( :$spec );

    return;

  }

  🐛 "Eco: Found candies [{@cand}] matching [$spec]";

  my $candy = @cand.sort( { Version.new: .version } ).tail;


  🐛 "Eco: Recommending candy [$candy] for spec [$spec]";

  $candy;

}

method list-dists ( ) {
  #TODO: list per source

  @!dist;

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

