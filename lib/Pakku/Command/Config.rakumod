use X::Pakku;
use Pakku::Log;

unit role Pakku::Command::Config;

my class Config { ... }

# config values arrive as strings from the command line
my sub boolish ( $value ) {
  return $value unless $value ~~ Str:D;
  given $value.lc {
    when 'true'  | 'yes' | 'on'  | '1' { True  }
    when 'false' | 'no'  | 'off' | '0' { False }
    default { $value }
  }
}

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

  submethod TWEAK ( ) { $!deps = boolish( $!deps ); die "deps: true, false, only, runtime, test or build!" unless $!deps ~~ Bool | 'only' | 'runtime' | 'test' | 'build' | 'all' | Any:U }

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

  submethod TWEAK ( ) { $!deps = boolish( $!deps ); die "deps: true, false, only, runtime, test or build!" unless $!deps ~~ Bool | 'only' | 'runtime' | 'test' | 'build' | 'all' | Any:U }

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

my class Build {

  has Int() $.timeout;   # quiet seconds before a build is killed, 0 never

}

my class Test {

  has Bool  $.build;
  has Bool  $.xtest;
  has Int() $.timeout;   # quiet seconds before a test is killed, 0 never

}

my class List {

  has Bool $.details;
  has Str  $.repo;

}

my class Search {

  has Bool  $.details;
  has Bool  $.relaxed;
  has Bool  $.latest;
  has Int() $.count;

}

# a recommendation manager: an ecosystem (mirrors serving an index) or a local directory of dists
my class Recman {

  has Str   $.name;
  has Str   $.type     where { !.defined or $_ eq 'ecosystem' | 'local' };
  has Str   $.location;
  has Str   @.mirrors;
  has Str   $.index;
  has Str   $.source   where { !.defined or $_ eq 'path' | 'source-url' };
  has Any   $.refresh;
  has Int() $.priority;
  has Bool  $.active;

  submethod TWEAK ( ) {

    $!refresh = boolish( $!refresh );
    $!refresh = +$!refresh if $!refresh ~~ Str:D and $!refresh ~~ / ^ \d+ $ /;

    die "refresh: hours, true or false!" unless $!refresh ~~ Bool | Int | Any:U;

  }

  # what the entry is when nobody said: mirrors make an ecosystem, a location a local recman
  method kind ( ) { $!type // ( @!mirrors ?? 'ecosystem' !! 'local' ) }

  # does the whole entry make sense
  method check ( ) {

    die "type: ecosystem (set mirrors) or local (set location)!" unless $!type.defined or @!mirrors or $!location;
    die "mirrors: an ecosystem needs mirrors!"                    if self.kind eq 'ecosystem' and not @!mirrors;
    die "location: a local recman needs a directory!"            if self.kind eq 'local'     and not $!location;
    die "location: not a directory! (an ecosystem takes mirrors)" if $!location and not $!location.IO.d;

    self;

  }

}

my class Log {

  has Str $.prefix;
  has Str $.msg-left-delimit;
  has Str $.msg-right-delimit;
  has Str $.comment-left-delimit;
  has Str $.comment-right-delimit;
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

    self!check-config-file-exists;

    # validate each option on its own and keep the typed value (Int, Bool, list), not the command line string
    my Pair @typed = @option.map( -> $option {

      my $value = try self!typed( $module, $option );

      if $! {

        log '🐞', header => 'CNF', msg => to-json( $option, :!pretty ), comment => 'invalid option! ' ~ $!.message.lines.head, :!msg-delimit;

        die X::Pakku::Cnf.new: msg => ~$module;
      }

      $option.key => $value;

    } );

    my %config-key;
    my $new-recman = False;

    log '🦋', header => 'CNF', msg => ~$module;

    given $module {

      when 'recman' {

        log '🦋', header => 'REC', msg => ~$recman-name;

        my $index = quietly %!configuration{ $module }.first( *.<name> eq $recman-name, :k );

        if defined $index {

          %config-key := %!configuration{ $module }[ $index ];

        } else {

          %!configuration{ $module }.unshift( { name => $recman-name, :1priority, :active } ); 

          %config-key := %!configuration{ $module }[ 0 ];

          $new-recman = True;

        }
      }

      when 'log' {

        log '🦋', header => 'LOG', msg => ~$log-level;

        %config-key := %!configuration{ $module }{ $log-level }

      }

      default { %config-key := %!configuration{ $module } }

    }

    @typed.map( -> $option {

      my $key   = $option.key;
      my $value = $option.value; 

      %config-key{ $key } = $value;

      %config-key{ $key }:delete without $value; # remove null values

      log '🦋', header => 'CNF', msg => to-json( $option, :!pretty ), :!msg-delimit;

    } );

    # a recman entry must make sense as a whole: new ones, and edits of what it is made of
    if $module eq 'recman' and ( $new-recman or @typed.map( *.key ).any eq any <type mirrors location source index refresh> ) {

      # hash values are itemized: a Map hands the list attributes real lists
      my $recman = try Recman.new( |Map.new( %config-key.kv.map( -> $k, $v { $k => $v<> } ) ) ).check;

      without $recman {

        log '🐞', header => 'REC', msg => ~$recman-name, comment => 'invalid recman! ' ~ $!.message.lines.head ~ ' (set mirrors https://mirror/ or location /dists)';

        die X::Pakku::Cnf.new: msg => ~$recman-name;

      }

      %config-key<type> = $recman.kind;

    }

    self!write-config;

  }

  # the attribute value after validation: 42 for "42", ["a", "b"] for a list, False for "false"
  method !typed ( Str:D $module, Pair:D $option ) {

    my $validator = self."$module"().new( |$option );

    die "no such option!" unless $validator.can( $option.key );

    my $value = $validator."{ $option.key }"();

    $value ~~ Positional ?? $value.Array !! $value;

  }

  multi method config ( Str:D $module, 'unset', :$recman-name! ) {

    self!check-config-file-exists;

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    log '🐞', header => 'REC', msg => ~$recman-name, comment => 'does not exist!' unless $recman;

    quietly log '🦋', header => 'CNF', msg => ~$recman-name, comment => "\n" ~ to-json $recman with $recman;

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

    self!check-config-file-exists;


    log '🐞', header => 'LOG', msg => ~$log-level, comment => 'does not exist!' unless %!configuration{ $module }{ $log-level }:exists;

    my $level = %!configuration{ $module }{ $log-level }:delete;

    quietly log '🦋', header => 'CNF', msg => ~$log-level, comment => "\n" ~ to-json $level with $level;

    self!write-config;

  }

  multi method config ( Str:D $module, 'view', Str :$recman-name!, Str :@option! )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    if $recman {

      log '🦋', header => 'REC', msg => ~$recman-name;

      @option.map( -> $option { out to-json $recman{ $option }:p } );

    } else {

      log '🐞', header => 'REC', msg => ~$recman-name, comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$recman-name! )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

    if $recman {

      log '🦋', header => 'REC', msg => ~$recman-name;

      my Str $json = to-json $recman;

      out $json;

    } else {

      log '🐞', header => 'REC', msg => ~$recman-name, comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$log-level!, Str :@option! )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    my $level = quietly %!configuration{ $module }{ $log-level };

    if $level {

      log '🦋', header => 'LOG', msg => ~$log-level;

      sink @option.map( -> $option { out to-json $level{ $option }:p } );

    } else {

      log '🐞', header => 'LOG', msg => ~$log-level, comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :$log-level! )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    my $level = quietly %!configuration{ $module }{ $log-level };

    if $level {

      log '🦋', header => 'LOG', msg => ~$log-level;

      my Str $json = to-json $level;

      out $json;

    } else {

      log '🐞', header => 'LOG', msg => ~$log-level, comment => 'does not exist!';

    }

  }

  multi method config ( Str:D $module, 'view', Str :@option! )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    sink @option.map( -> $option { out to-json %!configuration{ $module }{ $option }:p } );

  }

  multi method config ( Str:D $module, 'view'  )  {

    self!check-config-file-exists;

    log '🦋', header => 'CNF', msg => ~$module;

    my Str $json = to-json %!configuration{ $module };

    out $json;

  }


  multi method config ( Str:D $module, 'reset' )  {

    self!check-config-file-exists;

    # back to the built-in default; a module without one is simply gone
    if %!default-configuration{ $module }:exists {

      %!configuration{ $module } = %!default-configuration{ $module };

      my Str $json = to-json %!configuration{ $module };

      log '🦋', header => 'CNF', msg => ~$module, comment => "\n$json";

    } else {

      %!configuration{ $module }:delete;

      log '🦋', header => 'CNF', msg => ~$module, comment => 'no default, removed';

    }

    self!write-config;
    
  }

  multi method config ( Str:D $module, 'unset' )  {

    self!check-config-file-exists;

    my Str $json = to-json %!configuration{ $module }:delete;

    log '🦋', header => 'CNF', msg => ~$module, comment => "\n$json";

    self!write-config;
    
  }

  multi method config ( 'reset' ) {

    self!check-config-file-exists;

    %!configuration = %!default-configuration;

    self!write-config;
    
  }

  multi method config ( 'view' )  {

    self!check-config-file-exists;

    my Str $json = to-json %!configuration;

    out $json;

  }

  multi method config ( 'new' ) {

    log '🐛', header => 'CNF', msg => ~$!config-file;
    
    if $!config-file.e {

      log '🐞', header => 'CNF', msg => ~$!config-file, comment => 'already exists!';

      die X::Pakku::Cnf.new: msg => ~$!config-file; 

    }

    $!config-file.dirname.IO.mkdir( :mode( 0o700 ) ) unless $!config-file.dirname.IO.e;

    %!configuration = %!default-configuration;

    self!write-config;
    
    log '🧚', header => 'CNF', msg => ~$!config-file;
  }

  method !write-config ( ) {

    my Str:D $json = to-json %!configuration;

    $!config-file.spurt: $json;

    # mirrors may carry credentials
    try $!config-file.chmod: 0o600;

    log '🐛', header => 'CNF', msg => ~$!config-file, comment => "\n$json";
  }

  method !check-config-file-exists ( ) {

    log '🐛', header => 'CNF', msg => ~$!config-file;

    unless $!config-file.e {

      log '🐞', header => 'CNF', msg => ~$!config-file, comment => 'does not exist! to create: pakku config new';

      die X::Pakku::Cnf.new: msg => ~$!config-file; 

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
