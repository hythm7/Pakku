use Log::Async;
use Terminal::ANSIColor;

unit class Pakku::Log;

has Int  $.verbose;
has Bool $.pretty;


submethod TWEAK ( ) {

  $!verbose = INFO;

  # TODO: formatter
  #logger.send-to: $*OUT, :level( * >= INFO );

} 

method info ( Str:D $msg ) {

  logger.send-to: $*OUT, :level( * >= $!verbose );

  info $msg;

}
