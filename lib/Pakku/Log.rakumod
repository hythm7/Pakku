use Log::Async;
use Terminal::ANSIColor;

class Pakku::Log {

  has      %.cnf;
  has      $.verbose;
  has Bool $.pretty;


  submethod BUILD ( Int:D :$verbose!, Bool:D :$!pretty!, :$cnf ) {

    %!cnf<TRACE><name>    = $cnf<1><name>  // '🤓';
    %!cnf<DEBUG><name>    = $cnf<2><name>  // '🐞';
    %!cnf<INFO><name>     = $cnf<3><name>  // '🦋';
    %!cnf<WARNING><name>  = $cnf<4><name>  // '🔔';
    %!cnf<ERROR><name>    = $cnf<5><name>  // '❌';
    %!cnf<FATAL><name>    = $cnf<6><name>  // '💀';

    %!cnf<TRACE><color>   = $cnf<1><color> // '42';
    %!cnf<DEBUG><color>   = $cnf<2><color> // '14';
    %!cnf<INFO><color>    = $cnf<3><color> // '177';
    %!cnf<WARNING><color> = $cnf<4><color> // '220';
    %!cnf<ERROR><color>   = $cnf<5><color> // '9';
    %!cnf<FATAL><color>   = $cnf<6><color> // '1';


    my Int $color;

    $!verbose = $verbose ~~ 0 ?? 0 !! Loglevels( $verbose );

    my Code $level-formatter = -> $m, :$fh {

      my $color = %!cnf{ $m<level> }<color>;
      my $level = %!cnf{ $m<level> }<name>;
      my $msg   = $m<msg>;

      my $formatted =
        $!pretty
          ?? colored( "$level ", "bold $color" ) ~ colored( "$msg ", "$color" )
          !! "$level $msg";

      $fh.say: $formatted;

    }

    my Code $ofun-formatter = -> $m, :$fh {

      my $msg   = $m<msg>;
      my $color = 'bold 177';

      my $formatted =
        $!pretty
          ?? colored( $msg, $color )
          !! $msg;

      $fh.say: $formatted;

    }

    my Code $nofun-formatter = -> $m, :$fh {

      my $msg   = $m<msg>;
      my $color = 'bold 9';

      my $formatted =
        $!pretty
          ?? colored( $msg, $color )
          !! $msg;

      $fh.say: $formatted;

    }

    my Code $out-formatter = -> $m, :$fh {

      my $msg   = $m<msg>;

      my $formatted =
        $!pretty
          ?? $msg
          !! $msg;

      $fh.say: $formatted;

    }

    if $!verbose ~~ 0 {

      logger.untapped-ok = True;

    }

    else {

      my @fun  = < -Ofun Nofun >;
      my @info = < PRC: BLT: TST: ADD: CHK: >;

      logger.send-to: $*OUT, :level( INFO ), :msg( '-Ofun' ),        :formatter( $ofun-formatter);
      logger.send-to: $*OUT, :level( INFO ), :msg( 'Nofun' ),        :formatter( $nofun-formatter);
      logger.send-to: $*OUT, :level( INFO ), :msg( *.starts-with: none flat @info, @fun ),        :formatter( $out-formatter);

      logger.send-to: $*OUT, :level( INFO ), :msg( *.starts-with: any @info ), :formatter( $level-formatter ) if $!verbose ≤ INFO ;


      logger.send-to: $*OUT, :level( TRACE ),   :formatter( $level-formatter ) if $!verbose ≤ TRACE ;
      logger.send-to: $*OUT, :level( DEBUG ),   :formatter( $level-formatter ) if $!verbose ≤ DEBUG ;
      logger.send-to: $*ERR, :level( WARNING ), :formatter( $level-formatter ) if $!verbose ≤ WARNING;
      logger.send-to: $*ERR, :level( ERROR ),   :formatter( $level-formatter ) if $!verbose ≤ ERROR;
      logger.send-to: $*ERR, :level( FATAL ),   :formatter( $level-formatter ) if $!verbose ≤ FATAL;


    }
  }

}


sub prefix:<🤓> ( Str:D $msg ) is export { trace   $msg }
sub prefix:<🐞> ( Str:D $msg ) is export { debug   $msg }
sub prefix:<🦋> ( Str:D $msg ) is export { info    $msg }
sub prefix:<🔔> ( Str:D $msg ) is export { warning $msg }
sub prefix:<❌> ( Str:D $msg ) is export { error   $msg }
sub prefix:<💀> ( Str:D $msg ) is export { fatal   $msg }

sub ofun    ( )      is export { info '-Ofun'       ; exit 0 }
sub nofun   ( )      is export { info 'Nofun'       ; exit 1 }
