
unit role Pakku::Help;

submethod !add ( ) {

  'help add';

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
