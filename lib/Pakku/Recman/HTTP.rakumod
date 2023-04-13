use Pakku::Log;
use Pakku::Curl;

unit class Pakku::Recman::HTTP;

has Str:D         $.name     is required;
has Str:D         $.location is required;
has Pakku::Curl:D $!curl     is required is built;


method recommend ( ::?CLASS:D: :$spec! ) {

  🐛 REC ~ "｢$!name｣ $spec";

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
 

  $meta = retry { $!curl.content: URL => $!location ~ $uri };

  unless $meta {

    🐛 REC ~ "｢$!name｣ $spec not found!";

    return;

  }

  $meta;
  
}

method search ( ::?CLASS:D: :$spec!, Int :$count ) {

  🐛 REC ~ "｢$!name｣ $spec";

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

  my $meta;
 
  $meta = retry { $!curl.content: URL => $!location ~ $uri };

  unless $meta {

    🐛 REC ~ "｢$!name｣ $spec not found!";

    return;

  }

  Rakudo::Internals::JSON.from-json: $meta;
  
}

