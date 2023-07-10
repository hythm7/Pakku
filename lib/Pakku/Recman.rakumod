use Pakku::Log;
use Pakku::Spec;

use Pakku::Recman::HTTP;
use Pakku::Recman::Local;


unit class Pakku::Recman;

has @!recman;
 
submethod BUILD ( :$http!, :@recman! ) {

  @recman
    ==> grep( *.<active> )
    ==> sort( *.<priority> )
    ==> map( -> %recman {
      my $name     = %recman<name>;
      my $location = %recman<location>;
    $location.starts-with( 'http')
      ?? Pakku::Recman::HTTP.new(  :$http, |%recman )
      !! Pakku::Recman::Local.new( |%recman );
    } )
    ==> @!recman;
}

method recommend ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  for @!recman -> $recman { .return with $recman.recommend: :$spec }

}

method search (
    ::?CLASS:D:
    Pakku::Spec::Raku:D :$spec!,
    Bool:D              :$relaxed!,
    Int:D               :$count!,

  ) {

  flat @!recman.map: *.search: :$spec :$relaxed :$count;

}
