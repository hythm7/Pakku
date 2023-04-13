use Pakku::Log;
use Pakku::Spec;
use Pakku::Recman::Local;
use Pakku::Recman::HTTP;


unit class Pakku::Recman;

has @!recman;
 

submethod BUILD ( :$curl!, :@recman! ) {

  @recman
    ==> grep( *.<active> )
    ==> sort( *.<priority> )
    ==> map( -> %recman {
      my $name     = %recman<name>;
      my $location = %recman<location>;
    $location.starts-with( 'http')
      ?? Pakku::Recman::HTTP.new(  :$curl, |%recman )
      !! Pakku::Recman::Local.new(         |%recman );
    } )
    ==> @!recman;
}

method recommend ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  for @!recman -> $recman { .return with $recman.recommend: :$spec }

}

method search ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec!, Int :$count ) {

  for @!recman -> $recman { .return with $recman.search: :$spec }

}
