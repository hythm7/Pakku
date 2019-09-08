use X::Pakku;
use Log::Async;
use Terminal::ANSIColor;

unit class Pakku::Log;

has %.cnf;

has Loglevels  $.verbose;
has Bool       $.pretty;

has Str $!ofun;
has Str $!nofun;


submethod BUILD ( Int:D :$verbose!, Bool:D :$!pretty! ) {

  my Int $color;
  my %level-sym   = level-sym;
  my %level-color = level-color;

  $!ofun = $!pretty ?? colored( '-Ofun', %level-color<OFUN> ) !! '-Ofun';
  $!nofun = $!pretty ?? colored( 'NOfun', %level-color<NOFUN> ) !! 'NOfun';

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

  #logger.send-to: $*ERR, :level( * >= ERROR ),     :$formatter;
  logger.send-to: $*OUT, :level( * >= $!verbose ), :$formatter;

}


method trace ( Str:D $msg ) { trace $msg }
method debug ( Str:D $msg ) { debug $msg }
method info  ( Str:D $msg ) { info  $msg }
method warn  ( Str:D $msg ) { warn  $msg }
method error ( Str:D $msg ) { error $msg }

method out ( Str:D $msg ) { put $msg }

method ofun  ( ) { put $!ofun  }
method nofun ( ) { put $!nofun }

method fatal ( Str:D $msg ) {

  fatal $msg;

  sleep .1; # quick nap befor X

  X::Pakku.new.throw;

}


method instance ( ) { logger.instance }

sub level-sym (  ) {

  {

    TRACE   => 'T',
    DEBUG   => 'D',
    INFO    => '✓',
    WARNING => '⚠',
    ERROR   => '✗',
    FATAL   => 'F',

  }

}

sub level-color (  ) {

  {

    TRACE   => '42',
    DEBUG   => '14',
    INFO    => '177',
    WARNING => '220',
    ERROR   => '9',
    FATAL   => '1',
    OFUN    => '177',
    NOFUN   => '9',

  }

}
