use Pakku::Log;
use Pakku::Curl;
use Pakku::Spec;


unit class Pakku::Recman;

has $!curl = Pakku::Curl.new;

has @!url  = 'http://recman.pakku.org';


submethod BUILD ( :@recman ) {

  @!url = @recman.grep( *.value.<active> ).sort( *.value.<priority> ) if @recman; 
  
}

method recommend ( ::?CLASS:D: Pakku::Spec:D :$spec! ) {

	my $name = $spec.name;
	my $ver  = $spec.ver;
	my $auth = $spec.auth;
	my $api  = $spec.api;

  my $query = '/recommend';

  $query ~= '?name='  ~ $!curl.escape: $name;
  $query ~= '&ver='   ~ $!curl.escape: $ver  if $ver;
  $query ~= '&auth='  ~ $!curl.escape: $auth if $auth;
  $query ~= '&api='   ~ $!curl.escape: $api  if $api;

  my $meta;
 
  @!url.map( -> $url { last if $meta = try retry { $!curl.content: URL => $url ~ $query } } );

  return Empty unless $meta;

  $meta;
  
}

method search ( ::?CLASS:D: Pakku::Spec:D :$spec!, Int :$count ) {

  my $name = $spec.name;
	my $ver  = $spec.ver;
	my $auth = $spec.auth;
	my $api  = $spec.api;

  my $query = '/search';

  $query ~= '?name='  ~ $!curl.escape: $name;
  $query ~= '&ver='   ~ $!curl.escape: $ver   if $ver;
  $query ~= '&auth='  ~ $!curl.escape: $auth  if $auth;
  $query ~= '&api='   ~ $!curl.escape: $api   if $api;
  $query ~= '&count=' ~                $count if $count;

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

