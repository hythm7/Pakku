unit class Pakku::Log;

my class Level {

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
has $!verbose;


method out ( Str:D $msg ) {

  $*OUT.put: $!pretty ?? $msg !! $msg.subst(/\e\[ <[0..9;]>+ m/, '', :g);

}

my Pakku::Log $logger;

my enum LogLevel <silent debug now info warn error>;

submethod BUILD (

  Bool:D :$!pretty = True,
         :$!verbose = now,
         :%level,

) {

  $logger = self;

  $!verbose = LogLevel::{$!verbose};  

  return $logger if $!verbose == silent;

  my $color = '' unless $!pretty;

  $!debug = Level.new: :fh( $*OUT ) :prefix( %level<1><prefix> // '🐛 ' ) :color( $color // %level<1><color> // '32' ) if  debug ≥ $!verbose;
  $!now   = Level.new: :fh( $*OUT ) :prefix( %level<2><prefix> // '🦋 ' ) :color( $color // %level<2><color> // '36' ) if  now   ≥ $!verbose;
  $!info  = Level.new: :fh( $*OUT ) :prefix( %level<3><prefix> // '🧚 ' ) :color( $color // %level<3><color> // '35' ) if  info  ≥ $!verbose;
  $!warn  = Level.new: :fh( $*OUT ) :prefix( %level<4><prefix> // '🐞 ' ) :color( $color // %level<4><color> // '33' ) if  warn  ≥ $!verbose;
  $!error = Level.new: :fh( $*ERR ) :prefix( %level<5><prefix> // '🦗 ' ) :color( $color // %level<5><color> // '31' ) if  error ≥ $!verbose;

}

sub prefix:<🐛> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.debug.msg: $msg }
sub prefix:<🦋> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.now.msg:   $msg }
sub prefix:<🧚> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.info.msg:  $msg }
sub prefix:<🐞> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.warn.msg:  $msg }
sub prefix:<🦗> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.error.msg: $msg }

sub out  ( Str:D $msg ) is export { $logger.out: $msg }

sub ofun  ( ) is export { 🧚 '-Ofun'         }
sub nofun ( ) is export { 🦗 'Nofun'; exit 1 }

enum Color is export (

  reset   =>  0,
  black   => 30,
  red     => 31,
  green   => 32,
  yellow  => 33,
  blue    => 34,
  magenta => 35,
  cyan    => 36,
  white   => 37,

);

sub color ( Str:D $text, Color $color ) is export { "\e\[" ~ $color.Int ~ "m" ~ $text ~ "\e\[0m" }

