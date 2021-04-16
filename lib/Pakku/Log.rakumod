use Log::Async;
use Terminal::ANSIColor;

class Pakku::Log {

  has      %!level   is built;
  has Int  $!verbose is built;
  has Bool $!pretty  is built;


  submethod BUILD (

    Bool:D :$!pretty = True,
    Int:D  :$verbose = 3,
           :%level,

  ) {

    %!level<TRACE><prefix>    = %level<1><prefix>  // '🤓';
    %!level<DEBUG><prefix>    = %level<2><prefix>  // '🐞';
    %!level<INFO><prefix>     = %level<3><prefix>  // '🦋';
    %!level<WARNING><prefix>  = %level<4><prefix>  // '🔔';
    %!level<ERROR><prefix>    = %level<5><prefix>  // '❌';
    %!level<FATAL><prefix>    = %level<6><prefix>  // '💀';

    %!level<TRACE><color>   = %level<1><color> // '42';
    %!level<DEBUG><color>   = %level<2><color> // '14';
    %!level<INFO><color>    = %level<3><color> // '177';
    %!level<WARNING><color> = %level<4><color> // '220';
    %!level<ERROR><color>   = %level<5><color> // '9';
    %!level<FATAL><color>   = %level<6><color> // '1';


    my Int $color;

    $!verbose = $verbose ~~ 0 ?? 0 !! Loglevels( $verbose );

    my Code $level-formatter = -> $m, :$fh {

      my $color = %!level{ $m<level> }<color>;
      my $level = %!level{ $m<level> }<prefix>;
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
          !! colorstrip $msg;

      $fh.say: $formatted;

    }

    if $!verbose ~~ 0 {

      logger.untapped-ok = True;

    }

    else {

      my @fun  = < -Ofun Nofun >;
      my @info = < PRC: BLD: TST: ADD: PAC: CHK: BIN: RES: CNF: >;

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

sub ofun  ( ) is export { info '-Ofun'; exit 0 }
sub nofun ( ) is export { info 'Nofun'; exit 1 }
