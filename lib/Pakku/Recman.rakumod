use Pakku::Log;
use Pakku::Spec;

use Pakku::Recman::Local;


unit class Pakku::Recman;

has @!recman;
 
submethod BUILD ( :$fetch!, :@recman! ) {

  @recman
    ==> grep( *.<active> )
    ==> sort( *.<priority> )
    ==> map( -> %recman {
      my $name     = %recman<name>;
      my $location = %recman<location>;
    if $location.defined and $location.starts-with( 'http' ) {
      # the old recman.pakku.org protocol is gone; index-based ecosystems arrive with Pakku::Recman::Ecosystem
      log '🐞', header => 'REC', msg => ~$name, comment => "$location: recman protocol no longer supported, run: pakku config recman reset";
      Empty
    } else {
      Pakku::Recman::Local.new( |%recman )
    }
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
    Bool:D              :$latest!,
    Int:D               :$count!,

  ) {

  flat @!recman.map: *.search: :$spec :$relaxed :$latest :$count;

}
