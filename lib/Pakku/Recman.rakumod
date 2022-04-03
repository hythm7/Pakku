use Pakku::Log;
use Pakku::Curl;
use Pakku::Spec;


unit class Pakku::Recman;

has $!curl = Pakku::Curl.new;

has @!url is required is built;

method recommend ( ::?CLASS:D: Pakku::Spec:D :$spec! ) {

  my $query = '/recommend';

  $query ~= '?name='  ~ $!curl.escape: $spec.name;
  $query ~= '&ver='   ~ $!curl.escape: $_  with $spec.ver;
  $query ~= '&auth='  ~ $!curl.escape: $_  with $spec.auth;
  $query ~= '&api='   ~ $!curl.escape: $_  with $spec.api;

  my $meta;
 
  @!url.map( -> $url { last if $meta = try retry { $!curl.content: URL => $url ~ $query } } );

  return Empty unless $meta;

  $meta;
  
}

method search ( ::?CLASS:D: Pakku::Spec:D :$spec!, Int :$count ) {

  my $query = '/search';

  $query ~= '?name='  ~ $!curl.escape: $spec.name;
  $query ~= '&ver='   ~ $!curl.escape: $_  with $spec.ver;
  $query ~= '&auth='  ~ $!curl.escape: $_  with $spec.auth;
  $query ~= '&api='   ~ $!curl.escape: $_  with $spec.api;
  $query ~= '&count=' ~                $_  with $count;

  my $meta;
 
  @!url.map( -> $url { last if $meta = try retry { $!curl.content: URL => $url ~ $query } } );

  return Empty unless $meta;

  Rakudo::Internals::JSON.from-json: $meta;
  
}


method fetch ( Str:D :url( :$URL )!, Str:D :$download! ) {

  retry { $!curl.download: :$URL :$download }

}

sub retry (

  &action,
  Int:D  :$max   is copy = 4,
  Real:D :$delay is copy = 0.2

) {

  loop {

    my $result = try action();

    return $result unless $!;
    
    $!.rethrow if $max == 0;

    🐞 "REC: ｢$!.message()｣";

    sleep $delay;

    $delay *= 2;
    $max   -= 1;

  }
}

