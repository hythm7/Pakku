unit class Pakku::Log;

enum Color is export ( :reset(0) :black(30) :red(31) :green(32) :yellow(33) :blue(34) :magenta(35) :cyan(36) :white(37) );

my class Level {

  has Str:D $!prefix is required;

  has Str $!msg-left-delimit;
  has Str $!msg-right-delimit;
  has Str $!comment-left-delimit;
  has Str $!comment-right-delimit;

  has Str:D $!color  is required;
  has Str   $!reset-color;

  has IO::Handle $!fh is required;


  method msg (

    Str:D :$header!,
    Str:D :$msg!,
    Str:D :$comment = '',

    Bool  :$msg-delimit     = True,
    Bool  :$comment-delimit = False,

    ) {

    my ( $msg-left-delimit,     $msg-right-delimit     ) = $msg-delimit     ?? ( $!msg-left-delimit,     $!msg-right-delimit     )     !! ( '', '' );
    my ( $comment-left-delimit, $comment-right-delimit ) = $comment-delimit ?? ( $!comment-left-delimit, $!comment-right-delimit )     !! ( '', '' );

    $!fh.put: $!color                ~
              $!prefix               ~
              " "                    ~
              $header                ~
              ": "                   ~
              $msg-left-delimit      ~
              $msg                   ~
              $msg-right-delimit     ~
              " "                    ~
              $comment-left-delimit  ~
              $comment               ~
              $comment-right-delimit ~
              $!reset-color;

  }

  submethod BUILD (
    :$!fh!,
    :$!prefix!,
    :$!msg-left-delimit!,
    :$!msg-right-delimit!,
    :$!comment-left-delimit!,
    :$!comment-right-delimit!,
    :$color! ) {

    $!color       = $color  ?? "\e\[" ~ $color ~ "m" !! '';
    $!reset-color = $!color ?? "\e\[0m"              !! '';

  }

}

my class BarLevel {

  has Str:D $!prefix is required;

  has Str:D $!l-delim = '｢';
  has Str:D $!r-delim = '｣';

  has Str:D $.color  is required;
  has Str   $.reset-color;

  has IO::Handle $!fh is required;


  multi method msg ( BarLevel:D: Str:D :$header!, Str:D :$msg!, Str:D :$comment = '' ) {

    $!fh.print: $!color ~ "$!prefix $header: $!l-delim" ~ $!reset-color ~ $msg ~ $!color ~ $!r-delim ~ $!reset-color;

  }

  submethod BUILD ( :$!fh!, :$!prefix!, :$color!, :$complete-color, :$incomplete-color ) {

    $!color       = $color  ?? "\e\[" ~ $color ~ "m" !! '';
    $!reset-color = $!color ?? "\e\[0m"              !! '';

  }

}

my class SpinnerLevel {

  has Str:D $!prefix is required;

  has Str:D $!l-delim = '｢';
  has Str:D $!r-delim = '｣';

  has Str:D $.color  is required;
  has Str   $.reset-color;

  has IO::Handle $!fh is required;


  multi method msg ( SpinnerLevel:D: Str:D :$header!, Str:D :$msg!, Str:D :$comment = '' ) {

    $!fh.print: $!color ~ "$!prefix $header: $!l-delim" ~ $!reset-color ~ $msg ~ $!color ~ $!r-delim ~ $!reset-color;

  }

  submethod BUILD ( :$!fh!, :$!prefix!, :$color! ) {

    $!color       = $color  ?? "\e\[" ~ $color ~ "m" !! '';
    $!reset-color = $!color ?? "\e\[0m"              !! '';

  }


}

my class Bar {
  has BarLevel $.level;

  has Str  $.header = 'WAI';
  has Int  $.length = 42;

  has Str  @.sym    = ( '🦋' x $!length ).comb[ ^$!length ];

  has Int  $.percent = 0;

  has Bool $.active;

  has Str   $!complete-color;
  has Str   $!incomplete-color;

  has Int:D $!max-length = 42;

  submethod BUILD ( :$!level, :$complete-color, :$incomplete-color ) {

    $!complete-color   = $complete-color   ?? "\e\[" ~ $complete-color ~ "m"   !! $!level.color;
    $!incomplete-color = $incomplete-color ?? "\e\[" ~ $incomplete-color ~ "m" !! $!level.color;

  }


  method length  ( Int:D    $length  ) { $!length  = min( $length, $!max-length )  }
  method header  ( Str:D    $header  ) { $!header  = $header                       }
  method percent ( Int:D( ) $percent ) { $!percent = $percent                      }

  method sym ( Str:D $sym is copy = '🦋' ) {

    $sym = $sym.comb[ ^($!max-length - 3) ].join ~ '...' if $sym.chars > $!max-length;

    @!sym = ( $sym x $!length ).comb[ ^$!length ];

  }

  method activate   ( ) {
    $!active = True;
    $!percent = 0;
    self.show;
  }
  method deactivate ( ) {
    self.hide;
    $!active = False;
  }

  my $lock = Lock::Async.new;

  method show( ) {

    $lock.protect: {

      print "\r";

      $!level.msg: :$!header, msg => ~self; 

    }
  }

  method hide (  ) {

    $lock.protect: {

      my $space = $!length + @!sym.uniprops( 'East_Asian_Width' ).grep( 'W' ) + $!header.chars + 7;

      print "\r";
      print " " x $space ~ "\b \b" x $space;

    }

  }

  method Str ( ) {

    my $done = $!percent * $!length div 100;

    my $sym = @!sym[ ^$done ].join;

    $!complete-color ~ @!sym[ ^$done ].join ~ $!level.reset-color ~ $!incomplete-color ~ @!sym[ $done .. * ].join ~ $!level.reset-color;

  }

}

my class Spinner {

  has SpinnerLevel $.level;

  has Str  $.header = 'WAI';

  has @.frame    = '🐝🐛🦋🧚🐞🦗'.comb;

  has $!current-frame-index = 0;

  has Int:D $!max-length = 42;

  has Bool $.active;


  method header  ( Str:D    $header  ) { $!header  = $header                       }

  method frames ( @frame = '🐝🐛🦋🧚🐞🦗'.comb ) {

    @!frame = @frame.map( -> $frame {
      
      $frame.chars > $!max-length
        ?? $frame.comb[ ^($!max-length - 3) ].join ~ '...'
        !! $frame;

    } );

  }

  method activate   ( ) {
    $!active = True;
    $!current-frame-index = 0;
    self.show;
  }

  method deactivate ( ) {
    self.hide;
    $!active = False;
  }

  method next ( ) { 
    
    self.hide;

    $!current-frame-index = ( $!current-frame-index + 1 ) mod +@!frame;
    self.show;
    
  }

  method show ( ) {

    $!level.msg: :$!header, msg => ~@!frame[ $!current-frame-index ];
  }

  method hide (  ) {

    my $space = @!frame[ $!current-frame-index ].chars + @!frame[ $!current-frame-index ].uniprops( 'East_Asian_Width' ).grep( 'W' ) + $!header.chars + 7;

    print "\r";
    print " " x $space ~ "\b \b" x $space;

  }

}


has $!bar     is default( Nil );
has $!spinner is default( Nil );

has $!all   is default( Nil );
has $!debug is default( Nil );
has $!now   is default( Nil );
has $!info  is default( Nil );
has $!warn  is default( Nil );
has $!error is default( Nil );

has Bool $!pretty;
has      $!verbose;



my enum LogLevel <nothing error warn info now debug all>;

submethod BUILD (

  Bool:D :$!pretty = True,
         :$bar     = True,
         :$spinner = True,
         :$verbose = info,
         :%level,

) {

  $!verbose = LogLevel::{ $verbose } // info;  

  my %color = ( :0reset, :30black, :31red, :32green, :33yellow, :34blue, :35magenta, :36cyan, :37white );

  
  my $color = '' unless $!pretty;

  $!all   = Level.new(
    :fh( $*OUT )
    :prefix( %level<all><prefix>   // '🐝' )
    :color( $color // %color{ %level<all><color>   // 'reset'   } )
    :msg-left-delimit(      %level<all><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<all><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<all><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<all><msg-right-delimit> // '❩' )
  ) if  all   ≤ $!verbose;

  $!debug = Level.new(
    :fh( $*OUT )
    :prefix( %level<debug><prefix> // '🐛' )
    :color( $color // %color{ %level<debug><color> // 'green'   } )
    :msg-left-delimit(      %level<debug><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<debug><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<debug><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<debug><msg-right-delimit> // '❩' )
  ) if  debug ≤ $!verbose;

  $!now   = Level.new(
    :fh( $*OUT )
    :prefix( %level<now><prefix>   // '🦋' )
    :color( $color // %color{ %level<now><color>   // 'cyan'    } )
    :msg-left-delimit(      %level<now><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<now><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<now><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<now><msg-right-delimit> // '❩' )
  ) if  now   ≤ $!verbose;

  $!info  = Level.new(
    :fh( $*OUT )
    :prefix( %level<info><prefix>  // '🧚' )
    :color( $color // %color{ %level<info><color>  // 'magenta' }  )
    :msg-left-delimit(      %level<info><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<info><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<info><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<info><msg-right-delimit> // '❩' )
  ) if  info  ≤ $!verbose;

  $!warn  = Level.new(
    :fh( $*ERR )
    :prefix( %level<warn><prefix>  // '🐞' )
    :color( $color // %color{ %level<warn><color>  // 'yellow'  } )
    :msg-left-delimit(      %level<warn><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<warn><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<warn><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<warn><msg-right-delimit> // '❩' )
  ) if  warn  ≤ $!verbose;

  $!error = Level.new(
    :fh( $*ERR )
    :prefix( %level<error><prefix> // '🦗' )
    :color( $color // %color{ %level<error><color> // 'red'     } )
    :msg-left-delimit(      %level<error><msg-left-delimit>  // '｢' )
    :msg-right-delimit(     %level<error><msg-right-delimit> // '｣' )
    :comment-left-delimit(  %level<error><msg-left-delimit>  // '❨' )
    :comment-right-delimit( %level<error><msg-right-delimit> // '❩' )
    ) if  error ≤ $!verbose;

  if $bar {

    $!bar = Bar.new: :level( BarLevel.new: :fh( $*OUT ) :prefix( %level<info><prefix>  // '🧚' ) :color( $color // %color{ %level<info><color>  // 'magenta' } ) ) :complete-color( $color // %color{ %level<info><color>  // 'magenta' } ) :incomplete-color( $color // %color{ %level<now><color>  // 'cyan' } )  if info  ≤ $!verbose;

  }

  if $spinner {

    my @frame;

    @frame.push: $!pretty ?? color( %level<all><prefix>   // '🐝', reset   ) !! %level<all><prefix>   // '🐝';
    @frame.push: $!pretty ?? color( %level<debug><prefix> // '🐛', green   ) !! %level<debug><prefix> // '🐛';
    @frame.push: $!pretty ?? color( %level<now><prefix>   // '🦋', cyan    ) !! %level<now><prefix>   // '🦋';
    @frame.push: $!pretty ?? color( %level<info><prefix>  // '🧚', magenta ) !! %level<info><prefix>  // '🧚';
    @frame.push: $!pretty ?? color( %level<warn><prefix>  // '🐞', yellow  ) !! %level<warn><prefix>  // '🐞';
    @frame.push: $!pretty ?? color( %level<error><prefix> // '🦗', red     ) !! %level<error><prefix> // '🦗';

    $!spinner = Spinner.new: :level( SpinnerLevel.new: :fh( $*OUT ) :prefix( %level<info><prefix>  // '🧚' ) :color( $color // %color{ %level<info><color>  // 'magenta' } ) ) :@frame if info  ≤ $!verbose;

  }

  $!warn.msg: header => 'CNF', msg => ~$verbose, comment => 'unknown log level' unless LogLevel::{ $verbose }; 

  proto log ( | ) {

    if $!bar.active {

      $!bar.hide;
      {*}
      $!bar.show;

    } elsif $!spinner.active {

      $!spinner.hide;
      {*}
      $!spinner.show;
     
    } else {

      {*}

    }
  }

  multi sub log ( '🐝', *%opt ) is export {

    $!all.msg: |%opt;
  }

  multi sub log ( '🐛', *%opt ) is export {

    $!debug.msg: |%opt;

  }

  multi sub log ( '🦋', *%opt ) is export {

    $!now.msg: |%opt;
  }

  multi sub log ( '🧚', *%opt ) is export {

    $!info.msg: |%opt;

  }

  multi sub log ( '🐞', *%opt ) is export {

    $!warn.msg: |%opt;

  }

  multi sub log ( '🦗', *%opt ) is export {

    $!error.msg: |%opt;

  }

  sub out ( Str:D $msg ) is export {

    if $!bar.active {

      $!bar.hide;
      $*OUT.put: $!pretty ?? $msg !! $msg.subst(/\e\[ <[0..9;]>+ m/, '', :g);
      $!bar.show;

    } elsif  $!spinner.active {

      $!spinner.hide;
      $*OUT.put: $!pretty ?? $msg !! $msg.subst(/\e\[ <[0..9;]>+ m/, '', :g);
      $!spinner.show;
     
    } else {

      $*OUT.put: $!pretty ?? $msg !! $msg.subst(/\e\[ <[0..9;]>+ m/, '', :g);

    }

  }


  sub ofun ( Str:D :$header = 'FUN', Str:D :$msg = '-Ofun' ) is export {

    if $!bar.active {

      $!bar.hide;
      $!info.msg: :$header :$msg :!msg-delimit;

    } elsif $!spinner.active {

      $!spinner.hide;
      $!info.msg: :$header :$msg :!msg-delimit;

    } else {

      $!info.msg: :$header :$msg :!msg-delimit;

    }

  }

  sub nofun ( Str:D :$header = 'FUN' , Str:D :$msg = 'Nofun' ) is export {

    if $!bar.active {

      $!bar.hide;
      $!error.msg: :$header :$msg :!msg-delimit;

    } elsif $!spinner.active {

      $!spinner.hide;
      $!error.msg: :$header :$msg :!msg-delimit;

    } else {

      $!error.msg: :$header :$msg :!msg-delimit;

    }

  }

  sub bar     ( ) is export { $!bar     }
  sub spinner ( ) is export { $!spinner }

}


sub color ( Str:D $text, Color $color ) is export { "\e\[" ~ $color.Int ~ "m" ~ $text ~ "\e\[0m" }

