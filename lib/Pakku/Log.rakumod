unit class Pakku::Log;

class Level {

  has Str   $!reset;
  has Str:D $!color  is required;
  has Str:D $!prefix is required;

  has IO::Handle $!fh is required;


  multi method msg ( Level:D: $msg ) { $!fh.put: $!color ~ $!prefix ~ $msg ~ $!reset }
  multi method msg ( Level:U: $msg ) { return }

  submethod BUILD ( :$!fh!, :$!prefix!, :$color! ) {

    $!color = $color  ?? "\e\[" ~ $color ~ "m" !! '';
    $!reset = $!color ?? "\e\[0m"              !! '';

  }

}



has Level $.silent;
has Level $.debug;
has Level $.now;
has Level $.info;
has Level $.warn;
has Level $.error;

has Bool $!pretty;


method out ( Str:D $msg ) {

  $*OUT.put: $!pretty ?? $msg !! $msg.subst(/\e\[ <[0..9;]>+ m/, '', :g);

}

my Pakku::Log $logger;

my enum LogLevel <SILENT DEBUG NOW INFO WARN ERROR>;

submethod BUILD (

  Int:D  :$verbose = INFO,
  Bool:D :$!pretty = True,
         :%level,

) {

  $logger = self;

  return $logger if $verbose == SILENT;

  my $color = '' unless $!pretty;

  $!debug = Level.new: :fh( $*OUT ) :prefix( %level<1><prefix> // '🐛 ' ) :color( $color // %level<1><color> // '32' ) if  DEBUG ≥ $verbose;
  $!now   = Level.new: :fh( $*OUT ) :prefix( %level<2><prefix> // '🦋 ' ) :color( $color // %level<2><color> // '36' ) if  NOW   ≥ $verbose;
  $!info  = Level.new: :fh( $*OUT ) :prefix( %level<3><prefix> // '🧚 ' ) :color( $color // %level<3><color> // '35' ) if  INFO  ≥ $verbose;
  $!warn  = Level.new: :fh( $*OUT ) :prefix( %level<4><prefix> // '🐞 ' ) :color( $color // %level<4><color> // '33' ) if  WARN  ≥ $verbose;
  $!error = Level.new: :fh( $*ERR ) :prefix( %level<5><prefix> // '🦗 ' ) :color( $color // %level<5><color> // '31' ) if  ERROR ≥ $verbose;

}

sub prefix:<🐛> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.debug.msg: $msg }
sub prefix:<🦋> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.now.msg:   $msg }
sub prefix:<🧚> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.info.msg:  $msg }
sub prefix:<🐞> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.warn.msg:  $msg }
sub prefix:<🦗> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.error.msg: $msg }

sub out  ( Str:D $msg ) is export { $logger.out: $msg }

sub ofun  ( ) is export { 🧚 '-Ofun' }
sub nofun ( ) is export { 🦗 'Nofun' }

enum PRF is export (

  PRC => 'PRC: ',
  SPC => 'SPC: ',
  MTA => 'MTA: ',
  FTC => 'FTC: ',
  STG => 'STG: ',
  BLD => 'BLD: ',
  TST => 'TST: ',
  UPG => 'UPG: ',
  BIN => 'BIN: ',
  WAI => 'WAI: ',
  TOT => 'TOT: ',
  OLO => 'OLO: ',
  CNF => 'CNF: ',
  CMD => 'CMD: ',

);

enum Color is export (

  RESET   =>  0,
  BLACK   => 30,
  RED     => 31,
  GREEN   => 32,
  YELLOW  => 33,
  BLUE    => 34,
  MAGENTA => 35,
  CYAN    => 36,
  WHITE   => 37,

);

sub color ( Str:D $text, Color $color ) is export { "\e\[" ~ $color.Int ~ "m" ~ $text ~ "\e\[0m" }

