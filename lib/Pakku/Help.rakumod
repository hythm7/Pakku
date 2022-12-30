use Pakku::Log;

unit role Pakku::Help;

method help ( Str:D :$cmd ) {

  given $cmd {

    when 'add'      { out self!add-help      }
    when 'remove'   { out self!remove-help   }
    when 'list'     { out self!list-help     }
    when 'search'   { out self!search-help   }
    when 'upgrade'  { out self!upgrade-help  }
    when 'build'    { out self!build-help    }
    when 'test'     { out self!test-help     }
    when 'download' { out self!download-help }
    when 'help'     { out self!help-help     }


    default {
      out (
        self!add-help,
        self!remove-help,
        self!list-help,
        self!search-help,
        self!upgrade-help,
        self!build-help,
        self!test-help,
        self!download-help,
        self!pakku-help,
        self!help-help,
      ).join: "\n";
    }
  }
}

submethod !add-help ( ) {

  my %add;

  %add<cmd>     = 'Add';
  %add<desc>    = 'Add distribution';

  %add<example>.push: 'pakku add MyModule';
  %add<example>.push: 'pakku add nodeps MyModule';
  %add<example>.push: 'pakku add notest MyModule';
  %add<example>.push: 'pakku add exclude Dep MyModule';
  %add<example>.push: 'pakku add noprecomp notest MyModule';
  %add<example>.push: 'pakku add to     /opt/MyApp MyModule';
  %add<example>.push: 'pakku add force  to   home  MyModule1 MyModule2';

  %add<opt>.push: ( 'deps'            => 'add dependencies' );
  %add<opt>.push: ( 'nodeps'          => 'dont add dependencies' );
  %add<opt>.push: ( 'deps only'       => 'dont add the dist, only dependencies' );
  %add<opt>.push: ( 'build'           => 'build distribution' );
  %add<opt>.push: ( 'nobuild'         => 'bypass build' );
  %add<opt>.push: ( 'test'            => 'test distribution' );
  %add<opt>.push: ( 'notest'          => 'bypass test' );
  %add<opt>.push: ( 'xtest'           => 'xtest distribution' );
  %add<opt>.push: ( 'noxtest'         => 'bypass xtest' );
  %add<opt>.push: ( 'force'           => 'force add distribution even if installed' );
  %add<opt>.push: ( 'noforce'         => 'no force' );
  %add<opt>.push: ( 'precomp'         => 'precomp distribution' );
  %add<opt>.push: ( 'noprecomp'       => 'no precomp' );
  %add<opt>.push: ( 'exclude <dep>'   => 'add distribution but exclude specific dep' );
  %add<opt>.push: ( 'to <repo>'       => 'add distribution to repo <home site vendor core /path/to/MyApp>' );

  help %add;

}

submethod !remove-help ( ) {

  my %remove;

  %remove<cmd>     = 'Remove';
  %remove<desc>    = 'Remove distribution';

  %remove<example>.push: 'pakku remove MyModule';

  %remove<opt>.push: ( 'from <repo>' => 'remove distribution from provided repo only' );

  help %remove;

}

submethod !list-help ( ) {

  my %list;

  %list<cmd>     = 'List';
  %list<desc>    = 'List distribution details';

  %list<example>.push: 'pakku list';
  %list<example>.push: 'pakku list MyModule';
  %list<example>.push: 'pakku list details MyModule';
  %list<example>.push: 'pakku list repo home';
  %list<example>.push: 'pakku list repo /opt/MyApp MyModule';

  %list<opt>.push: ( 'details'     => 'list details' );
  %list<opt>.push: ( 'repo <name>' => 'list repo' );

  help %list;

}

submethod !search-help ( ) {

  my %search;

  %search<cmd>     = 'Search';
  %search<desc>    = 'Search distribution on Recman';

  %search<example>.push: 'pakku search MyModule';
  %search<example>.push: 'pakku search count 5 MyModule';
  %search<example>.push: 'pakku search details MyModule';

  %search<opt>.push: ( 'count'       => 'distributions count' );
  %search<opt>.push: ( 'details'     => 'search details' );

  help %search;

}

submethod !upgrade-help ( ) {

  my %upgrade;

  %upgrade<cmd>     = 'Upgrade';
  %upgrade<desc>    = 'Upgrade distribution';

  %upgrade<example>.push: 'pakku upgrade MyModule';
  %upgrade<example>.push: 'pakku upgrade nodeps MyModule';
  %upgrade<example>.push: 'pakku upgrade notest MyModule';
  %upgrade<example>.push: 'pakku upgrade exclude Dep MyModule';
  %upgrade<example>.push: 'pakku upgrade in     /opt/MyApp MyModule';
  %upgrade<example>.push: 'pakku upgrade force  in   vendor  MyModule1 MyModule2';

  %upgrade<opt>.push: ( 'deps'            => 'upgrade dependencies' );
  %upgrade<opt>.push: ( 'nodeps'          => 'dont upgrade dependencies' );
  %upgrade<opt>.push: ( 'deps only'       => 'upgrade dependencies only' );
  %upgrade<opt>.push: ( 'build'           => 'build distribution' );
  %upgrade<opt>.push: ( 'nobuild'         => 'bypass build' );
  %upgrade<opt>.push: ( 'test'            => 'test distribution' );
  %upgrade<opt>.push: ( 'notest'          => 'bypass test' );
  %upgrade<opt>.push: ( 'xtest'           => 'xtest distribution' );
  %upgrade<opt>.push: ( 'noxtest'         => 'bypass xtest' );
  %upgrade<opt>.push: ( 'force'           => 'force upgrade' );
  %upgrade<opt>.push: ( 'noforce'         => 'no force' );
  %upgrade<opt>.push: ( 'precomp'         => 'precomp distribution' );
  %upgrade<opt>.push: ( 'noprecomp'       => 'no precomp' );
  %upgrade<opt>.push: ( 'exclude <dep>'   => 'upgrade distribution but exclude specific dep' );
  %upgrade<opt>.push: ( 'in <repo>'       => 'upgrade distribution in repo <home site vendor core /path/to/MyApp>' );

  help %upgrade;

}


submethod !build-help ( ) {

  my %build;

  %build<cmd>     = 'Build';
  %build<desc>    = 'Build distribution';

  %build<example>.push: 'pakku build MyModule';
  %build<example>.push: 'pakku build .';

  help %build;


}

submethod !test-help ( ) {

  my %test;

  %test<cmd>     = 'Test';
  %test<desc>    = 'Test distribution';

  %test<example>.push: 'pakku test MyModule';
  %test<example>.push: 'pakku test ./MyModule';
  %test<example>.push: 'pakku test xtest ./MyModule';
  %test<example>.push: 'pakku test nobuild ./MyModule';

  %test<opt>.push: ( 'xtest'   => 'xtest distribution' );
  %test<opt>.push: ( 'noxtest' => 'bypass xtest' );
  %test<opt>.push: ( 'build'   => 'build distribution' );
  %test<opt>.push: ( 'nobuild' => 'dont build distribution' );

  help %test;

}

submethod !download-help ( ) {

  my %download;

  %download<cmd>     = 'Download';
  %download<desc>    = 'Download distribution';

  %download<example>.push: 'pakku download MyModule';

  help %download;

}

submethod !help-help ( ) {

  my %help;

  %help<cmd>     = 'Help';
  %help<desc>    = 'Print help';

  %help<example>.push: 'pakku';
  %help<example>.push: 'pakku add';
  %help<example>.push: 'pakku upgrade';
  %help<example>.push: 'pakku help';
  %help<example>.push: 'pakku help list';
  %help<example>.push: 'pakku help help';

  help %help;

}

submethod !pakku-help ( ) {

  my %pakku;

  %pakku<cmd>     = 'Pakku';
  %pakku<desc>    = 'Pakku Options';

  %pakku<example>.push: 'pakku dont     add MyModule';
  %pakku<example>.push: 'pakku async    add MyModule';
  %pakku<example>.push: 'pakku nocache  add MyModule';
  %pakku<example>.push: 'pakku norecman add MyModule';
  %pakku<example>.push: 'pakku nopretty add MyModule';
  %pakku<example>.push: 'pakku verbose  debug  add    MyModule';
  %pakku<example>.push: 'pakku pretty   please remove MyModule';

  %pakku<opt>.push: ( 'pretty'          => 'colorfull butterfly'  );
  %pakku<opt>.push: ( 'nopretty'        => 'no color' );
  %pakku<opt>.push: ( 'nocache'         => 'disable cache' );
  %pakku<opt>.push: ( 'norecman'        => 'disable recman' );
  %pakku<opt>.push: ( 'dont'            => 'do everything but dont do it' );
  %pakku<opt>.push: ( 'async'           => 'run asynchronously when possible' );
  %pakku<opt>.push: ( 'yolo'            => 'dont stop on Pakku exceptions' );
  %pakku<opt>.push: ( 'please'          => 'be nice to butterflies' );
  %pakku<opt>.push: ( 'verbose <level>' => 'verbose level <silent debug now info warn error>' );
  %pakku<opt>.push: ( 'config  <path>'  => 'specify config file' );

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

  color( "$cmd: \n", MAGENTA ) ~
  color( $desc, CYAN ) ~ "\n";

}

sub example ( @example ) {

  return '' unless any @example;
  "\n" ~
  color( "Examples:\n", YELLOW ) ~
  color( @example.join( "\n" ), MAGENTA ) ~ "\n";

}

sub opt ( @opt ) {

  return '' unless any @opt;
  my $indent  = @opt.map( *.key.chars ).max if @opt;
  "\n" ~
  color( "Options:\n", YELLOW ) ~ 
  @opt.map( {
    color( .key, GREEN )  ~
    color( ' → ', YELLOW ).indent( $indent - .key.chars ) ~
    color( .value, CYAN )
  } ).join( "\n" ) ~ "\n";
 
}
