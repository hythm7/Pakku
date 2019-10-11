use Terminal::ANSIColor;

unit role Pakku::Help;

method help ( Str:D :$cmd ) {

  given $cmd {

    when 'add'    { self!add    }
    when 'build'  { self!build  }
    when 'test'   { self!test   }
    when 'remove' { self!remove }
    when 'check'  { self!check  }
    when 'list'   { self!list   }


    default {
      (
        self!add,
        self!build,
        self!test,
        self!remove,
        self!check,
        self!list,
      )
      .join: "\n";
    }
  }
}

submethod !add ( ) {

  my %add;

  %add<cmd>     = 'Add';
  %add<desc>    = 'Add distribution';

  %add<example>.push: 'pakku add MyModule';
  %add<example>.push: 'pakku add nodeps MyModule';
  %add<example>.push: 'pakku add notest MyModule';
  %add<example>.push: 'pakku add force into home MyModule';

  %add<opt>.push: ( 'deps'            => 'add dependencies as well' );
  %add<opt>.push: ( 'nodeps'          => 'dont add dependencies' );
  %add<opt>.push: ( 'deps requires'   => 'add required dependencies' );
  %add<opt>.push: ( 'deps recommends' => 'add required and recommended dependencies' );
  %add<opt>.push: ( 'deps only'       => 'add dependencies only' );
  %add<opt>.push: ( 'build'           => 'build distribution' );
  %add<opt>.push: ( 'nobuild'         => 'bypass build' );
  %add<opt>.push: ( 'test'            => 'test distribution' );
  %add<opt>.push: ( 'notest'          => 'bypass test' );
  %add<opt>.push: ( 'force'           => 'force add distribution even if it is installed' );
  %add<opt>.push: ( 'noforce'         => 'no force' );
  %add<opt>.push: ( 'into <repo>'     => 'add distribution to specified repo <home site vendor core>' );

  my $indent = %add<opt>.map( *.key.chars ).max;

  q:s:a:h:f:to/END/
  &colored( %add<cmd>, 'bold magenta' ): &colored( %add<desc>, 'cyan' )

  &colored( 'Example:', 'bold yellow' )
  &colored( %add<example>.join( "\n" ), 'bold italic 177' )

  &colored( 'Options:', 'bold yellow' )
  %add<opt>.map( {
    &colored( .key, 'bold green' )  ~
    &colored( ' → ', 'yellow' ).indent( $indent - .key.chars )     ~
    &colored( .value, 'bold cyan' )
  } ).join( "\n" )
  END

}

submethod !build ( ) {

  'help build';

}

submethod !test ( ) {

  'help test';

}

submethod !remove ( ) {

  'help remove';

}

submethod !check ( ) {

  'help check';

}

submethod !list ( ) {

  'help list';

}


