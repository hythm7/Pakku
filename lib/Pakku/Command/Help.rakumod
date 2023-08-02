use Pakku::Log;

unit role Pakku::Command::Help;

multi method fly ( 'help',  Str:D :$cmd ) {

  given $cmd {

    when 'add'      { out self!add-help      }
    when 'remove'   { out self!remove-help   }
    when 'list'     { out self!list-help     }
    when 'search'   { out self!search-help   }
    when 'state'    { out self!state-help    }
    when 'update'   { out self!update-help   }
    when 'build'    { out self!build-help    }
    when 'test'     { out self!test-help     }
    when 'download' { out self!download-help }
    when 'nuke'     { out self!nuke          }
    when 'config'   { out self!config-help   }
    when 'help'     { out self!help-help     }


    default {
      out (
        self!add-help,
        self!remove-help,
        self!list-help,
        self!search-help,
        self!state-help,
        self!update-help,
        self!build-help,
        self!test-help,
        self!download-help,
        self!nuke-help,
        self!config-help,
        self!pakku-help,
        self!help-help,
      ).join: "\n";
    }
  }
}

method !add-help ( ) {

  my %add;

  %add<cmd>     = 'Add';
  %add<desc>    = 'Add distribution';

  %add<example>.push: 'pakku add dist';
  %add<example>.push: 'pakku add notest dist';
  %add<example>.push: 'pakku add nodeps dist';
  %add<example>.push: 'pakku add serial dist';
  %add<example>.push: 'pakku add deps only dist';
  %add<example>.push: 'pakku add exclude Dep dist';
  %add<example>.push: 'pakku add noprecomp notest dist';
  %add<example>.push: 'pakku add to     /opt/MyApp dist';
  %add<example>.push: 'pakku add force  to   home  dist1 dist2';

  %add<opt>.push: ( 'deps'            => 'add all dependencies' );
  %add<opt>.push: ( 'nodeps'          => 'dont add dependencies' );
  %add<opt>.push: ( 'deps only'       => 'dont add the dist, only dependencies' );
  %add<opt>.push: ( 'deps build'      => 'build dependencies' );
  %add<opt>.push: ( 'deps test'       => 'test dependencies' );
  %add<opt>.push: ( 'deps runtime'    => 'runtime dependencies' );
  %add<opt>.push: ( 'build'           => 'build distribution' );
  %add<opt>.push: ( 'nobuild'         => 'bypass build' );
  %add<opt>.push: ( 'test'            => 'test distribution' );
  %add<opt>.push: ( 'notest'          => 'bypass test' );
  %add<opt>.push: ( 'xtest'           => 'xtest distribution' );
  %add<opt>.push: ( 'noxtest'         => 'bypass xtest' );
  %add<opt>.push: ( 'force'           => 'force add distribution even if installed' );
  %add<opt>.push: ( 'noforce'         => 'no force' );
  %add<opt>.push: ( 'serial'          => 'add distribution in serial order' );
  %add<opt>.push: ( 'noserial'        => 'no serial' );
  %add<opt>.push: ( 'precomp'         => 'precomp distribution' );
  %add<opt>.push: ( 'noprecomp'       => 'no precomp' );
  %add<opt>.push: ( 'exclude <dep>'   => 'add distribution but exclude specific dep' );
  %add<opt>.push: ( 'to <repo>'       => 'add distribution to repo <home site vendor core /path/to/MyApp>' );

  help %add;

}

method !remove-help ( ) {

  my %remove;

  %remove<cmd>     = 'Remove';
  %remove<desc>    = 'Remove distribution';

  %remove<example>.push: 'pakku remove dist';

  %remove<opt>.push: ( 'from <repo>' => 'remove distribution from provided repo only' );

  help %remove;

}

method !list-help ( ) {

  my %list;

  %list<cmd>     = 'List';
  %list<desc>    = 'List distribution details';

  %list<example>.push: 'pakku list';
  %list<example>.push: 'pakku list dist';
  %list<example>.push: 'pakku list details dist';
  %list<example>.push: 'pakku list repo home';
  %list<example>.push: 'pakku list repo /opt/MyApp dist';

  %list<opt>.push: ( 'details'     => 'list details' );
  %list<opt>.push: ( 'repo <name>' => 'list repo' );

  help %list;

}

method !search-help ( ) {

  my %search;

  %search<cmd>     = 'Search';
  %search<desc>    = 'Search distribution on Recman';

  %search<example>.push: 'pakku search           dist';
  %search<example>.push: 'pakku search norelaxed dist';
  %search<example>.push: 'pakku search count 5   dist';
  %search<example>.push: 'pakku search details   dist';

  %search<opt>.push: ( 'relaxed' => 'relaxed search' );
  %search<opt>.push: ( 'count'   => 'distributions count' );
  %search<opt>.push: ( 'details' => 'search details' );

  help %search;

}

method !update-help ( ) {

  my %update;

  %update<cmd>     = 'Update';
  %update<desc>    = 'Update distribution';

  %update<example>.push: 'pakku update';
  %update<example>.push: 'pakku update noclean';
  %update<example>.push: 'pakku update dist';
  %update<example>.push: 'pakku update nodeps dist';
  %update<example>.push: 'pakku update notest dist';
  %update<example>.push: 'pakku update exclude Dep dist';
  %update<example>.push: 'pakku update in     /opt/MyApp dist';
  %update<example>.push: 'pakku update force  in   vendor  dist1 dist2';

  %update<opt>.push: ( 'clean'         => 'clean not needed dists' );
  %update<opt>.push: ( 'noclean'       => 'dont clean' );
  %update<opt>.push: ( 'deps'          => 'update dependencies' );
  %update<opt>.push: ( 'nodeps'        => 'dont update dependencies' );
  %update<opt>.push: ( 'deps only'     => 'update dependencies only' );
  %update<opt>.push: ( 'build'         => 'build distribution' );
  %update<opt>.push: ( 'nobuild'       => 'bypass build' );
  %update<opt>.push: ( 'test'          => 'test distribution' );
  %update<opt>.push: ( 'notest'        => 'bypass test' );
  %update<opt>.push: ( 'xtest'         => 'xtest distribution' );
  %update<opt>.push: ( 'noxtest'       => 'bypass xtest' );
  %update<opt>.push: ( 'force'         => 'force update' );
  %update<opt>.push: ( 'noforce'       => 'no force' );
  %update<opt>.push: ( 'precomp'       => 'precomp distribution' );
  %update<opt>.push: ( 'noprecomp'     => 'no precomp' );
  %update<opt>.push: ( 'exclude <dep>' => 'update distribution but exclude specific dep' );
  %update<opt>.push: ( 'in <repo>'     => 'update distribution in repo <home site vendor core /path/to/MyApp>' );

  help %update;

}

method !state-help ( ) {

  my %state;

  %state<cmd>     = 'State';
  %state<desc>    = 'State distribution';

  %state<example>.push: 'pakku state';
  %state<example>.push: 'pakku state dist';
  %state<example>.push: 'pakku state clean dist';
  %state<example>.push: 'pakku state noupdates dist';

  %state<opt>.push: ( 'updates'            => 'check for dists updates' );
  %state<opt>.push: ( 'clean'            => 'clean older versions' );
  %state<opt>.push: ( 'noclean'          => 'dont clean older versions' );
  

  help %state;

}


method !build-help ( ) {

  my %build;

  %build<cmd>     = 'Build';
  %build<desc>    = 'Build distribution';

  %build<example>.push: 'pakku build dist';
  %build<example>.push: 'pakku build .';

  help %build;

}

method !test-help ( ) {

  my %test;

  %test<cmd>     = 'Test';
  %test<desc>    = 'Test distribution';

  %test<example>.push: 'pakku test dist';
  %test<example>.push: 'pakku test ./dist';
  %test<example>.push: 'pakku test xtest ./dist';
  %test<example>.push: 'pakku test nobuild ./dist';

  %test<opt>.push: ( 'xtest'   => 'xtest distribution' );
  %test<opt>.push: ( 'noxtest' => 'bypass xtest' );
  %test<opt>.push: ( 'build'   => 'build distribution' );
  %test<opt>.push: ( 'nobuild' => 'dont build distribution' );

  help %test;

}

method !download-help ( ) {

  my %download;

  %download<cmd>     = 'Download';
  %download<desc>    = 'Download distribution';

  %download<example>.push: 'pakku download dist';

  help %download;

}

method !nuke-help ( ) {

  my %nuke;

  %nuke<cmd>     = 'Nuke';
  %nuke<desc>    = 'Nuke directories';

  %nuke<example>.push: 'pakku nuke cache';
  %nuke<example>.push: 'pakku nuke pakku';
  %nuke<example>.push: 'pakku nuke home';
  %nuke<example>.push: 'pakku nuke site';
  %nuke<example>.push: 'pakku nuke vendor';

  help %nuke;

}


method !config-help ( ) {

  my %config;

  %config<cmd>     = 'config';
  %config<desc>    = 'change configurations in config file';

  %config<example>.push: 'pakku config';
  %config<example>.push: 'pakku config new';
  %config<example>.push: 'pakku config add';
  %config<example>.push: 'pakku config add precompile';
  %config<example>.push: 'pakku config add disable precompile';
  %config<example>.push: 'pakku config add set to home';
  %config<example>.push: 'pakku config pakku unset verbose';
  %config<example>.push: 'pakku config recman MyRec disable';
  %config<example>.push: 'pakku config add reset';

  %config<opt>.push: ( 'enable'      => 'enable option' );
  %config<opt>.push: ( 'disable'     => 'disable option' );
  %config<opt>.push: ( 'set <value>' => 'set option to value' );
  %config<opt>.push: ( 'unset'       => 'unset option' );

  help %config;

}

method !help-help ( ) {

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

method !pakku-help ( ) {

  my %pakku;

  %pakku<cmd>     = 'Pakku';
  %pakku<desc>    = 'Pakku Options';

  %pakku<example>.push: 'pakku dont     add dist';
  %pakku<example>.push: 'pakku async    add dist';
  %pakku<example>.push: 'pakku nocache  add dist';
  %pakku<example>.push: 'pakku norecman add dist';
  %pakku<example>.push: 'pakku nopretty add dist';
  %pakku<example>.push: 'pakku verbose  debug  add    dist';
  %pakku<example>.push: 'pakku pretty   please remove dist';

  %pakku<opt>.push: ( 'pretty'           => 'colorfull butterfly'  );
  %pakku<opt>.push: ( 'nopretty'         => 'no color' );
  %pakku<opt>.push: ( 'nocache'          => 'disable cache' );
  %pakku<opt>.push: ( 'recman'           => 'use all available recommendation managers' );
  %pakku<opt>.push: ( 'norecman'         => 'disable all recommendation managers' );
  %pakku<opt>.push: ( 'recman   <MyRec>' => 'use MyRec recommendation manager only' );
  %pakku<opt>.push: ( 'norecman <MyRec>' => 'use all available recommendation managers except MyRec' );
  %pakku<opt>.push: ( 'dont'             => 'do everything but dont do it' );
  %pakku<opt>.push: ( 'async'            => 'run asynchronously when possible' );
  %pakku<opt>.push: ( 'yolo'             => 'dont stop on Pakku exceptions' );
  %pakku<opt>.push: ( 'please'           => 'be nice to butterflies' );
  %pakku<opt>.push: ( 'verbose <level>'  => 'verbose level <nothing all debug now info warn error>' );
  %pakku<opt>.push: ( 'config  <path>'   => 'specify config file' );

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

  color( "$cmd: \n", magenta ) ~
  color( $desc, cyan ) ~ "\n";

}

sub example ( @example ) {

  return '' unless any @example;
  "\n" ~
  color( "Examples:\n", yellow ) ~
  color( @example.join( "\n" ), magenta ) ~ "\n";

}

sub opt ( @opt ) {

  return '' unless any @opt;
  my $indent  = @opt.map( *.key.chars ).max if @opt;
  "\n" ~
  color( "Options:\n", yellow ) ~ 
  @opt.map( {
    color( .key, green )  ~
    color( ' → ', yellow ).indent( $indent - .key.chars ) ~
    color( .value, cyan )
  } ).join( "\n" ) ~ "\n";
 
}
