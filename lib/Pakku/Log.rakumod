unit class Pakku::Log;

my class Level {

  has Str   $!reset;
  has Str:D $!color  is required;
  has Str:D $!prefix is required;

  has IO::Handle $!fh is required;


  multi method msg ( Level:D: $msg ) { $!fh.put: $!color ~ $!prefix ~ " " ~ $msg ~ $!reset }
  multi method msg ( Level:U: $msg ) { return }

  submethod BUILD ( :$!fh!, :$!prefix!, :$color! ) {

    $!color = $color  ?? "\e\[" ~ $color ~ "m" !! '';
    $!reset = $!color ?? "\e\[0m"              !! '';

  }

}



has Level $.nothing;
has Level $.all;
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

my enum LogLevel <nothing all debug now info warn error>;


submethod BUILD (

  Bool:D :$!pretty = True,
         :$verbose = now,
         :%level,

) {
  $logger = self;

  $!verbose = LogLevel::{ $verbose } // now;  

  return $logger if $!verbose == nothing;

  my %color = ( :0reset, :30black, :31red, :32green, :33yellow, :34blue, :35magenta, :36cyan, :37white );

  
  my $color = '' unless $!pretty;

  $!all   = Level.new: :fh( $*OUT ) :prefix( %level<all><prefix>   // '🐝' ) :color( $color // %color{ %level<all><color>   // 'reset'   } ) if  all   ≥ $!verbose;
  $!debug = Level.new: :fh( $*OUT ) :prefix( %level<debug><prefix> // '🐛' ) :color( $color // %color{ %level<debug><color> // 'green'   } ) if  debug ≥ $!verbose;
  $!now   = Level.new: :fh( $*OUT ) :prefix( %level<now><prefix>   // '🦋' ) :color( $color // %color{ %level<now><color>   // 'cyan'    } ) if  now   ≥ $!verbose;
  $!info  = Level.new: :fh( $*OUT ) :prefix( %level<info><prefix>  // '🧚' ) :color( $color // %color{ %level<info><color>  // 'magenta' } ) if  info  ≥ $!verbose;
  $!warn  = Level.new: :fh( $*OUT ) :prefix( %level<warn><prefix>  // '🐞' ) :color( $color // %color{ %level<warn><color>  // 'yellow'  } ) if  warn  ≥ $!verbose;
  $!error = Level.new: :fh( $*ERR ) :prefix( %level<error><prefix> // '🦗' ) :color( $color // %color{ %level<error><color> // 'red' } // 31 ) if  error ≥ $!verbose;

  $logger.warn.msg: qq[CNF: ｢$verbose｣ unknown log level!] unless LogLevel::{ $verbose }; 

}

sub prefix:<🐝> ( Str:D $msg ) is export is looser( &infix:<~> ) { $logger.all.msg:   $msg }
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

