use Log::Async;
use Terminal::ANSIColor;

unit class Pakku::Log;

has Loglevels  $.verbose;
has Bool       $.pretty;

submethod BUILD ( Int:D :$verbose = 3, Bool:D :$!pretty = True ) {

  my Int $color;
  my %level-sym   = level-sym;
  my %level-color = level-color;

  $!verbose = Loglevels( $verbose );

  my Code $formatter = -> $m, :$fh {

    my $color = %level-color{ $m<level> };

    my $level = %level-sym{ $m<level> };
    my $msg   = $m<msg>;

    my $formatted = $!pretty ??
      colored( "$level ", "bold $color" ) ~ colored( "$msg ", "$color" )  !!
      "$level $msg";

    $fh.say: $formatted;

  }

  logger.send-to: $*ERR, :level( * >= ERROR ),     :$formatter;
  logger.send-to: $*OUT, :level( * >= $!verbose ), :$formatter;

}

method info ( Str:D $msg ) {

  info $msg;

}

method error ( Str:D $msg ) {

  error $msg;

}

sub level-sym (  ) {

  {

    TRACE   => 'T',
    DEBUG   => 'D',
    INFO    => 'I',
    WARNING => 'W',
    ERROR   => 'E',
    FATAL   => 'F',

  }

}

sub level-color (  ) {

  {

    TRACE   => '0',
    DEBUG   => '14',
    INFO    => '177',
    WARNING => '220',
    ERROR   => '9',
    FATAL   => '1',

  }

}
