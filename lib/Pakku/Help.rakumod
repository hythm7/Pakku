use Terminal::ANSIColor;

unit role Pakku::Help;

method help ( Str:D :$cmd ) {
  # TODO: Better description for options
  given $cmd {

    when 'add'      { self!add    }
    when 'remove'   { self!remove }
    when 'list'     { self!list   }
    when 'build'    { self!build  }
    when 'test'     { self!test   }
    when 'pack'     { self!test   }
    when 'checkout' { self!checkout  }
    when 'help'     { self!help   }


    default {
      (
        self!add,
        self!remove,
        self!list,
        self!build,
        self!test,
        self!pack,
        self!checkout,
        self!pakku,
        self!help,
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
  %add<example>.push: 'pakku add to     /opt/MyApp MyModule';
  %add<example>.push: 'pakku add force  to   home  MyModule1 MyModule2';

  %add<opt>.push: ( 'deps'            => 'add dependencies' );
  %add<opt>.push: ( 'nodeps'          => 'dont add dependencies' );
  %add<opt>.push: ( 'deps requires'   => 'add required dependencies only' );
  %add<opt>.push: ( 'deps recommends' => 'add required and recommended dependencies' );
  %add<opt>.push: ( 'deps only'       => 'dont add the dist, only dependencies' );
  %add<opt>.push: ( 'build'           => 'build distribution' );
  %add<opt>.push: ( 'nobuild'         => 'bypass build' );
  %add<opt>.push: ( 'test'            => 'test distribution' );
  %add<opt>.push: ( 'notest'          => 'bypass test' );
  %add<opt>.push: ( 'force'           => 'force add distribution even if installed' );
  %add<opt>.push: ( 'noforce'         => 'no force' );
  %add<opt>.push: ( 'to <repo>'       => 'add distribution to repo <home site vendor core /path/to/MyApp>' );

  help %add;

}

submethod !remove ( ) {

  my %remove;

  %remove<cmd>     = 'Remove';
  %remove<desc>    = 'Remove distribution';

  %remove<example>.push: 'pakku remove MyModule';

  %remove<opt>.push: ( 'from <repo>' => 'remove distribution from provided repo only' );

  help %remove;

}

submethod !list ( ) {

  my %list;

  %list<cmd>     = 'List';
  %list<desc>    = 'List distribution details';

  %list<example>.push: 'pakku list';
  %list<example>.push: 'pakku list MyModule';
  %list<example>.push: 'pakku list local   MyModule';
  %list<example>.push: 'pakku list remote  MyModule';
  %list<example>.push: 'pakku list details MyModule';
  %list<example>.push: 'pakku list repo home';
  %list<example>.push: 'pakku list repo /opt/MyApp MyModule';

  %list<opt>.push: ( 'local'       => 'list local'  );
  %list<opt>.push: ( 'remote'      => 'list remote'  );
  %list<opt>.push: ( 'details'     => 'list details' );
  %list<opt>.push: ( 'repo <name>' => 'list repo' );

  help %list;

}

submethod !pack ( ) {

  my %pack;

  %pack<cmd>     = 'Pack';
  %pack<desc>    = 'Pack rakudo and distribution';

  %pack<example>.push: 'pakku pack MyModule';
  %pack<example>.push: 'pakku pack notest MyModule';
  %pack<example>.push: 'pakku pack rakudo 2020.10 MyModule';
  %pack<example>.push: 'pakku pack to     /opt/MyApp MyModule';

  %pack<opt>.push: ( 'to <path>'       => 'pack to path /path/to/MyApp>' );
  %pack<opt>.push: ( 'rakudo version'  => 'package rakudo specific version' );
  %pack<opt>.push: ( '<addopt>'  => 'options available for add command are available hereas well' );

  help %pack;

}



submethod !build ( ) {

  my %build;

  %build<cmd>     = 'Build';
  %build<desc>    = 'Build distribution';

  %build<example>.push: 'pakku build MyModule';
  %build<example>.push: 'pakku build .';

  help %build;


}

submethod !test ( ) {

  my %test;

  %test<cmd>     = 'Test';
  %test<desc>    = 'Test distribution';

  %test<example>.push: 'pakku test MyModule';
  %test<example>.push: 'pakku test ./MyModule';

  help %test;

}

submethod !checkout ( ) {

  my %checkout;

  %checkout<cmd>     = 'Checkout';
  %checkout<desc>    = 'Download distribution';

  %checkout<example>.push: 'pakku checkout MyModule';

  help %checkout;

}

submethod !help ( ) {

  my %help;

  %help<cmd>     = 'Help';
  %help<desc>    = 'Print help';

  %help<example>.push: 'pakku';
  %help<example>.push: 'pakku add';
  %help<example>.push: 'pakku help';
  %help<example>.push: 'pakku help list';
  %help<example>.push: 'pakku help help';

  help %help;

}

submethod !pakku ( ) {

  my %pakku;

  %pakku<cmd>     = 'Pakku';
  %pakku<desc>    = 'Pakku Options';

  %pakku<example>.push: 'pakku dont     add MyModule';
  %pakku<example>.push: 'pakku nopretty add MyModule';
  %pakku<example>.push: 'pakku verbose  trace  add    MyModule';
  %pakku<example>.push: 'pakku pretty   please remove MyModule';

  %pakku<opt>.push: ( 'pretty'          => 'colorfull butterfly'  );
  %pakku<opt>.push: ( 'nopretty'        => 'no color' );
  %pakku<opt>.push: ( 'dont'            => 'do everything but dont do it' );
  %pakku<opt>.push: ( 'yolo'            => 'dont stop on Pakku exceptions' );
  %pakku<opt>.push: ( 'verbose <level>' => 'verbose level <silent trace debug info warn error fatal>' );
  %pakku<opt>.push: ( 'please' => 'be nice to the butterfly, she will be nice to you (TBD)' );

  help %pakku;

}

sub help ( %cmd --> Str:D ) {

  my $cmd     = %cmd<cmd>;
  my $desc    = %cmd<desc>;
  my @example = %cmd<example>.flat;
  my @opt     = %cmd<opt>.flat;

  q:s:f:c:to/END/
  {
    desc( $cmd, $desc ) ~
    example( @example ) ~
    opt( @opt )
  }
  END

}

sub desc ( $cmd, $desc ) {

  colored( "$cmd: \n", 'bold magenta' ) ~
  colored( $desc, 'cyan' ) ~ "\n";

}

sub example ( @example ) {

  return '' unless any @example;
  "\n" ~
  colored( "Examples:\n", 'bold yellow' ) ~
  colored( @example.join( "\n" ), 'italic 177' ) ~ "\n";

}

sub opt ( @opt ) {

  return '' unless any @opt;
  my $indent  = @opt.map( *.key.chars ).max if @opt;
  "\n" ~
  colored( "Options:\n", 'bold yellow' ) ~ 
  @opt.map( {
    colored( .key, 'green' )  ~
    colored( ' → ', 'yellow' ).indent( $indent - .key.chars ) ~
    colored( .value, 'cyan' )
  } ).join( "\n" ) ~ "\n";
 

}
