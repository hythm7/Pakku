use Pakku::Log;
use Pakku::Curl;
use Pakku::Spec;


unit class Pakku::Recman;

has $!curl = Pakku::Curl.new;

has @!recman;
 

submethod BUILD ( :@recman! ) {

  @!recman = @recman.grep( *.<active> ).sort( *.<priority> ); 

}

method recommend ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  my $name = $!curl.escape( $spec.name );

  my $ver  = $spec.ver;
  my $auth = $spec.auth;
  my $api  = $spec.api;

  my @query;

  @query.push( 'ver='  ~ $!curl.escape: $ver) if $ver;
  @query.push( 'auth=' ~ $!curl.escape: $auth)if $auth;
  @query.push( 'api='  ~ $!curl.escape: $api) if $api;

  my $uri = '/meta/recommend/' ~ $name;

  $uri ~= '?' ~ @query.join( '&') if @query;

  my $meta;
 
  @!recman.map( -> $recman {

    🐛 REC ~ "｢$recman<name>｣";

    last if $meta = try retry { $!curl.content: URL => $recman<url> ~ $uri };

    🐞 REC ~ "｢$recman<name>｣ $!.message()";

  } );

  return Empty unless $meta;

  $meta;
  
}

method search ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec!, Int :$count ) {

  my $name = $!curl.escape( $spec.name );

  my $ver  = $spec.ver;
  my $auth = $spec.auth;
  my $api  = $spec.api;

  my @query;

  @query.push( 'ver='   ~ $!curl.escape: $ver   ) if $ver;
  @query.push( 'auth='  ~ $!curl.escape: $auth  ) if $auth;
  @query.push( 'api='   ~ $!curl.escape: $api   ) if $api;
  @query.push( 'count=' ~                $count ) if $count;

  my $uri = '/meta/search/' ~ $name;

  $uri ~= '?' ~ @query.join( '&') if @query;

  dd $uri;

  my $meta;
 
  @!recman.map( -> $recman {

    🐛 REC ~ "｢$recman<name>｣";

    last if $meta = try retry { $!curl.content: URL => $recman<url> ~ $uri }

    🐞 REC ~ "｢$recman<name>｣ .message()" with $!;

  } );

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

    my $result = quietly try action();

    return $result unless $!;
    
    🐞 CRL ~ $!;

    $!.rethrow if $max == 0;

    sleep $delay;

    $delay *= 2;
    $max   -= 1;

  }
}

