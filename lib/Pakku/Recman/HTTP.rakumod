use Pakku::Log;
use Pakku::HTTP;

unit class Pakku::Recman::HTTP;

has Str:D         $.name     is required;
has Str:D         $.location is required;
has Pakku::HTTP:D $!http     is required is built;

method recommend ( ::?CLASS:D: :$spec! ) {

  🐛 qq[REC: ｢$spec｣ ‹$!name› recommending...];

  my $name = $spec.name;
  my $ver  = $spec.ver;
  my $auth = $spec.auth;
  my $api  = $spec.api;

  my @query;

  @query.push( 'ver='  ~ url-encode $ver  ) if $ver;
  @query.push( 'auth=' ~ url-encode $auth ) if $auth;
  @query.push( 'api='  ~ url-encode $api  ) if $api;

  my $uri = $!location ~ '/meta/recommend/' ~ url-encode $name;

  $uri ~= '?' ~ @query.join( '&') if @query;

  🐛 qq[REC: ｢$uri｣];

  my $response;
 
  retry {
    $response = $!http.get: $uri;

    unless $response<success> {

      die X::Pakku::HTTP.new: :$response, message => $response<reason> unless $response<status> == 404;  
    }

  }

  my $meta = $response<content>.decode if $response<content>;

  return unless $meta;

  🐛 qq[REC: ｢$spec｣ ‹$!name› found];

  $meta;
  
}

method search (

    ::?CLASS:D:
    :$spec!,
    :$relaxed!,
    :$count!,

  ) {

  🐛 qq[REC: ｢$spec｣ ‹$!name› searching...];

  my $name = $spec.name;
  my $ver  = $spec.ver;
  my $auth = $spec.auth;
  my $api  = $spec.api;

  my @query;

  @query.push( 'ver='     ~ url-encode $ver     ) if $ver;
  @query.push( 'auth='    ~ url-encode $auth    ) if $auth;
  @query.push( 'api='     ~ url-encode $api     ) if $api;
  @query.push( 'count='   ~ url-encode $count   ) if $count;
  @query.push( 'relaxed=' ~ url-encode $relaxed ) if $relaxed;

  my $uri = $!location ~ '/meta/search/' ~ url-encode $name;

  $uri ~= '?' ~ @query.join( '&') if @query;

  🐛 qq[REC: ｢$uri｣];

  my $response;

  retry {

    $response = $!http.get: $uri;

    unless $response<success> {

      die X::Pakku::HTTP.new: :$response, message => $response<reason> unless $response<status> == 404;  

    }

  }

  my $meta = $response<content>.decode if $response<content>;

  unless $meta {

    🐛 qq[REC: ｢$spec｣ ‹$!name› not found!];

    return;

  }

  🐛 qq[REC: ｢$spec｣ ‹$!name› found];

  Rakudo::Internals::JSON.from-json: $meta;
  
}

sub retry (

  &action,
  Int:D  :$max   is copy = 4,
  Real:D :$delay is copy = 0.2

) is export {

  loop {

    my $result = quietly try action();

    return $result unless $!;
    
    🐞 qq[REC: $!];

    $!.rethrow if $max == 0;

    sleep $delay;

    🐛 qq[REC: retrying!];

    $delay *= 2;
    $max   -= 1;

  }
}

sub url-encode ( Str() $text --> Str ) {
  return $text.subst:
    /<-[
      ! * ' ( ) ; : @ + $ , / ? # \[ \]
      0..9 A..Z a..z \- . ~ _
    ]> /,
      { .Str.encode».fmt('%%%02X').join }, :g;
}
