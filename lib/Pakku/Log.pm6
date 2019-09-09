use X::Pakku;
use Log::Async;
use Terminal::ANSIColor;

unit class Pakku::Log;

has %.cnf;

has Loglevels  $.verbose;
has Bool       $.pretty;

has Str $!ofun;
has Str $!nofun;


submethod BUILD ( Int:D :$verbose!, Bool:D :$!pretty!, :$cnf ) {

  %!cnf<TRACE><name>    = $cnf<1><name>  // 'T';
  %!cnf<DEBUG><name>    = $cnf<2><name>  // 'D';
  %!cnf<INFO><name>     = $cnf<3><name>  // '✓';
  %!cnf<WARNING><name>  = $cnf<4><name>  // '⚠';
  %!cnf<ERROR><name>    = $cnf<5><name>  // '✗';
  %!cnf<FATAL><name>    = $cnf<6><name>  // 'F';

  %!cnf<TRACE><color>   = $cnf<1><color> // '42';
  %!cnf<DEBUG><color>   = $cnf<2><color> // '14';
  %!cnf<INFO><color>    = $cnf<3><color> // '177';
  %!cnf<WARNING><color> = $cnf<4><color> // '220';
  %!cnf<ERROR><color>   = $cnf<5><color> // '9';
  %!cnf<FATAL><color>   = $cnf<6><color> // '1';

  %!cnf<OFUN><color>    = '177';
  %!cnf<NOFUN><color>   = '9';

  #say %cnf;


  my Int $color;

  $!ofun  = $!pretty ?? colored( '-Ofun', %!cnf<OFUN><color> )  !! '-Ofun';
  $!nofun = $!pretty ?? colored( 'NOfun', %!cnf<NOFUN><color> ) !! 'NOfun';

  $!verbose = Loglevels( $verbose );

  my Code $formatter = -> $m, :$fh {

    my $color = %!cnf{ $m<level> }<color>;
    my $level = %!cnf{ $m<level> }<name>;
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

  # quick nap befor X
  sleep .1;

  X::Pakku.new.throw;

}
