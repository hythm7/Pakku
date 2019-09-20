use Log::Async;
use Terminal::ANSIColor;

class Pakku::Log {

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

    logger.send-to: $*OUT, :level( * >= $!verbose ), :$formatter;

  }

  method out ( Str:D $msg ) { put $msg if $msg }

  method ofun  ( ) { put $!ofun  }
  method nofun ( ) { put $!nofun }

}


sub prefix:<T> ( Str:D $msg ) is export { trace   $msg }
sub prefix:<D> ( Str:D $msg ) is export { debug   $msg }
sub prefix:<✓> ( Str:D $msg ) is export { info    $msg }
sub prefix:<⚠> ( Str:D $msg ) is export { warning $msg }
sub prefix:<✗> ( Str:D $msg ) is export { error   $msg }
sub prefix:<☠> ( Str:D $msg ) is export { fatal   $msg }

