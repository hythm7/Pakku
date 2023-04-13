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

  my $meta;

  @!recman.map( -> $recman {

    🐛 REC ~ "｢$recman.name()｣";

    last if $meta = try $recman.recommend: :$spec;

    🐞 REC ~ "｢$recman.name()｣ $!.message()";

  } );

  return Empty unless $meta;

  $meta;

}

method search ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec!, Int :$count ) {

  my @meta;

  @!recman.map( -> $recman {

    🐛 REC ~ "｢$recman.name()｣";

    last if @meta = try $recman.search: :$spec;

    🐞 REC ~ "｢$recman.name()｣ $!.message()";

  } );

  return Empty unless @meta;

  @meta;

}
