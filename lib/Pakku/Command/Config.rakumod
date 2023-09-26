use X::Pakku;
use Pakku::Log;

unit role Pakku::Command::Config;

my class Config { ... }

multi method fly ( 'config', *%config ) {

  my @arg;
  my %arg;

  my $module      = %config<module>      if %config<module>;
  my $operation   = %config<operation>   if %config<operation>;
  my $recman-name = %config<recman-name> if %config<recman-name>;
  my $log-level   = %config<log-level>   if %config<log-level>;
  my $option      = %config<option>      if %config<option>;

  @arg.push( $module    ) if $module; 
  @arg.push( $operation ) if $operation; 

  %arg<recman-name> =  $recman-name if $recman-name; 
  %arg<log-level>   =  $log-level   if $log-level; 
  %arg<option>      =  $option      if $option; 

  Config.new( config-file => self!cnf<pakku><config> ).config( |@arg, |%arg );

}

my class Pakku {

  has Bool  $.pretty;
  has Bool  $.force;
  has Bool  $.async;
  has Any   $.cache;
  has Bool  $.yolo;
  has Bool  $.please;
  has Bool  $.dont;
  has Bool  $.bar;
  has Bool  $.spinner;
  has Any   $.recman;
  has Any   $.norecman;
  has Str   $.verbose;
  has Int() $.cores;

}

my class Add {

  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.serial;
  has Bool $.contained;
  has Bool $.precompile;
  has Any  $.deps;
  has Str  $.to;
  has Str  @.exclude;

}

my class Update {

  has Bool $.clean;
  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.precompile;
  has Any  $.deps;
  has Str  $.in;
  has Str  @.exclude;

}

my class State {

  has Bool $.clean;
  has Bool $.updates;

}


my class Remove {

  has Str  $.from;

}

my class Download { }

my class Nuke { }

my class Build    { }

my class Test {

  has Bool $.build;
  has Bool $.xtest;

}

my class List {

  has Bool $.details;
  has Str  $.repo;

}

my class Search {

  has Bool  $.details;
  has Bool  $.relaxed;
  has Int() $.count;

}

my class Recman {

  has Str   $.name;
  has Str   $.location;
  has Int() $.priority;
  has Bool  $.active;

}

my class Log {

  has Str $.prefix;
  has Any $.color;

}

my class Config {

  has Pakku    $.pakku;
  has Add      $.add;
  has Update   $.update;
  has Search   $.search;
  has Remove   $.remove;
  has Build    $.build;
  has Test     $.test;
  has List     $.list;
  has Download $.download;
  has Nuke     $.nuke;
  has State    $.state;
  has Recman   $.recman;
  has Log      $.log;

  has $!config-file;

  has %!default-configuration;
  has %!configuration;


  multi method config ( Str:D $module, Pair:D :@option!, Str :$recman-name, Str :$log-level ) {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;

    # smart match against pair
    @option.map( -> $option {

      unless try self."$module"().new( |$option ) ~~ $option {

        log '🐞', header => 'CNF', msg => to-json( $option, :!pretty ), comment => 'invalid option!';

        die X::Pakku::Cnf.new( cnf => "$module" );
      }

    } );

    my %config-key;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    given $module {

      when 'recman' {

        log '🦋', header => 'REC', msg => "｢$recman-name｣";

        my $index = quietly %!configuration{ $module }.first( *.<name> eq $recman-name, :k );

        if defined $index {

          %config-key := %!configuration{ $module }[ $index ];

        } else {

          %!configuration{ $module }.unshift( { name => $recman-name, :1priority, :active } ); 

          %config-key := %!configuration{ $module }[ 0 ];

        }
      }

      when 'log' {

        log '🦋', header => 'LOG', msg => "｢$log-level｣";

        %config-key := %!configuration{ $module }{ $log-level }

      }

      default { %config-key := %!configuration{ $module } }

    }

    @option.map( -> $option {

      my $key   = $option.key;
      my $value = $option.value; 

      %config-key{ $key } = $value;

      %config-key{ $key }:delete without $value; # remove null values

      log '🦋', header => 'CNF', msg => to-json( $option, :!pretty );

    } );

    self!write-config;

  }

  multi method config ( Str:D $module, 'unset', :$recman-name! ) {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    log '🐞', header => 'REC', msg => "｢$recman-name｣", comment => 'does not exist!' unless $recman;

    quietly log '🦋', header => 'CNF', msg => "｢$recman-name｣", comment => "\n" ~ to-json $recman with $recman;

    %!configuration{ $module } .= grep( not *.<name> eq $recman-name );

    self!write-config;

  }

  multi method config ( Str:D $module, 'enable', :$recman-name! ) {

    my Pair @option = :active;

    samewith $module, :@option, :$recman-name;

  }

  multi method config ( Str:D $module, 'disable', :$recman-name! ) {

    my Pair @option = :!active;

    samewith $module, :$recman-name, :@option;

  }


  multi method config ( Str:D $module, 'unset', :$log-level! ) {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;


    log '🐞', header => 'LOG', msg => "｢$log-level｣", comment => 'does not exist!' unless %!configuration{ $module }{ $log-level }:exists;

    my $level = %!configuration{ $module }{ $log-level }:delete;

    quietly log '🦋', header => 'CNF', msg => "｢$log-level｣", comment => "\n" ~ to-json $level with $level;

    self!write-config;

  }

  multi method config ( Str:D $module, 'view', Str :$recman-name!, Str :@option! )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    if $recman {

      log '🦋', header => 'REC', msg => "｢$recman-name｣";

      @option.map( -> $option { out to-json $recman{ $option }:p } );

    } else {

      log '🐞', header => 'REC', msg => "｢$recman-name｣", comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$recman-name! )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    if $recman {

      log '🦋', header => 'REC', msg => "｢$recman-name｣";

      my Str $json = to-json $recman;

      out $json;

    } else {

      log '🐞', header => 'REC', msg => "｢$recman-name｣", comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$log-level!, Str :@option! )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    my $level = quietly %!configuration{ $module }{ $log-level };

    if $level {

      log '🦋', header => 'LOG', msg => "｢$level｣";

      @option.map( -> $option { out to-json $level{ $option }:p } );

    } else {

      log '🐞', header => 'LOG', msg => "｢$log-level｣", comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$log-level! )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    my $level = quietly %!configuration{ $module }{ $log-level };

    if $level {

      log '🦋', header => 'LOG', msg => "｢$log-level｣";

      my Str $json = to-json $level;

      out $json;

    } else {

      log '🐞', header => 'LOG', msg => "｢$log-level｣", comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :@option! )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    sink @option.map( -> $option { out to-json %!configuration{ $module }{ $option }:p } );

  }

  multi method config ( Str:D $module, 'view'  )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => "｢$module｣";

    my Str $json = to-json %!configuration{ $module };

    out $json;

  }


  multi method config ( Str:D $module, 'reset' )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    %!configuration{ $module } = %!default-configuration{ $module };

    my Str $json = to-json %!configuration{ $module };

    log '🦋', header => 'CNF', msg => "｢$module｣", comment => "\n$json";

    self!write-config;
    
  }

  multi method config ( Str:D $module, 'unset' )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    my Str $json = to-json %!configuration{ $module }:delete;

    log '🦋', header => 'CNF', msg => "｢$module｣", comment => "\n$json";

    self!write-config;
    
  }

  multi method config ( 'reset' ) {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    self!check-config-file-exists;

    %!configuration = %!default-configuration;

    self!write-config;
    
  }

  multi method config ( 'view' )  {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";

    self!check-config-file-exists;

    my Str $json = to-json %!configuration;

    out $json;

  }

  multi method config ( 'new' ) {

    log '🐛', header => 'CNF', msg => "｢$!config-file｣";
    
    if $!config-file.e {

      log '🐞', header => 'CNF', msg => "｢$!config-file｣", comment => 'already exists!';

      die X::Pakku::Cnf.new: cnf => $!config-file; 

    }

    $!config-file.dirname.IO.mkdir unless $!config-file.dirname.IO.e;

    %!configuration = %!default-configuration;

    self!write-config;
    
    log '🧚', header => 'CNF', msg => "｢$!config-file｣";
  }

  method !write-config ( ) {

    my Str:D $json = to-json %!configuration;

    $!config-file.spurt: $json;

    log '🐛', header => 'CNF', msg => "｢$!config-file｣", comment => "\n$json";
  }

  method !check-config-file-exists ( ) {

    unless $!config-file.e {

      log '🐞', header => 'CNF', msg => "｢$!config-file｣", comment => 'does not exist! to create: pakku config new';

      die X::Pakku::Cnf.new: cnf => $!config-file; 

    }

  }

  method configuration ( ) { %!configuration }

  submethod BUILD ( IO :$!config-file! ) {

    %!default-configuration = from-json slurp %?RESOURCES<config.json>;

    %!configuration = from-json slurp $!config-file if $!config-file.e;

  }

  sub from-json ( Str $json --> Hash:D ) { Rakudo::Internals::JSON.from-json: $json }

  sub to-json ( \obj, :$pretty = True  --> Str:D ) { Rakudo::Internals::JSON.to-json: obj, :$pretty, :sorted-keys; }
}
