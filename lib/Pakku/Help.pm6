use Terminal::ANSIColor;

unit role Pakku::Help;

my %help;

%help<add><opt> = < deps nodeps "deps requires" "deps recommends" "deps only" >;


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

  my $cmd = 'add';
  q:s:a:h:f:to/END/
  &colored( $cmd, 'bold green' ): &colored( 'Adds Raku Distribution', 'yellow' )

  &colored( 'pakku add MyModule', 'bold 177' )

  &colored( ~%help<add><opt>, 'bold cyan' )

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


