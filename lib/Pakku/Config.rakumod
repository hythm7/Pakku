use X::Pakku;
use Pakku::Log;

unit class Pakku::Config;

my class Pakku {

  has Bool $.pretty;
  has Bool $.async;
  has Any  $.cache;
  has Bool $.yolo;
  has Bool $.please;
  has Bool $.dont;
  has Any  $.recman;
  has Any  $.norecman;
  has Str  $.verbose;

}

my class Add {

  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.force;
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
  has Bool $.force;
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

has Pakku    $.pakku;
has Add      $.add;
has Update   $.update;
has Search   $.search;
has Remove   $.remove;
has Build    $.build;
has Test     $.test;
has List     $.list;
has Download $.download;
has State    $.state;
has Recman   $.recman;
has Log      $.log;

has $!config-file;

has %!default-configuration;
has %!configuration;


multi method config ( Str:D $module, Pair:D :@option!, Str :$recman-name, Str :$log-level ) {

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;

  # smart match against pair
  @option.map( -> $option {

    unless try self."$module"().new( |$option ) ~~ $option {

      🐞 "CNF: " ~ "｢{ to-json $option, :!pretty }｣ invalid option";

      die X::Pakku::Cnf.new( cnf => "$module" );
    }

  } );

  my %config-key;

  🦋 qq[CNF: ｢$module｣];

  given $module {

    when 'recman' {

      🦋 qq[REC: ｢$recman-name｣];

      my $index = quietly %!configuration{ $module }.first( *.<name> eq $recman-name, :k );

      if defined $index {

        %config-key := %!configuration{ $module }[ $index ];

      } else {

        %!configuration{ $module }.unshift( { name => $recman-name, :1priority, :active } ); 

        %config-key := %!configuration{ $module }[ 0 ];

      }
    }

    when 'log' {

      🦋 qq[LOG: ｢$log-level｣];

      %config-key := %!configuration{ $module }{ $log-level }

    }

    default { %config-key := %!configuration{ $module } }

  }

  @option.map( -> $option {

    my $key   = $option.key;
    my $value = $option.value; 

    %config-key{ $key } = $value;

    %config-key{ $key }:delete without $value; # remove null values

    🦋 qq[CNF: ｢{ to-json $option, :!pretty }｣];

  } );

  self!write-config;

}

multi method config ( Str:D $module, 'unset', :$recman-name! ) {

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;

  my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

  🐞 qq[REC: ｢$recman-name｣ does not exist!] unless $recman;

  quietly 🦋 "CNF: " ~ "｢$recman-name｣" ~ "\n" ~ to-json $recman with $recman;

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

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;


  🐞 qq[LOG: ｢$log-level｣ does not exist!] unless %!configuration{ $module }{ $log-level }:exists;

  my $level = %!configuration{ $module }{ $log-level }:delete;

  quietly 🦋 "CNF: " ~ "｢$log-level｣" ~ "\n" ~ to-json $level with $level;

  self!write-config;
}

multi method config ( Str:D $module, 'view', Str :$recman-name!, Str :@option! )  {

  🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

  if $recman {

    🦋 qq[REC: ｢$recman-name｣];

    @option.map( -> $option { out to-json $recman{ $option }:p } );

  } else {

    🐞 qq[REC: ｢$recman-name｣ does not exist!];

  }

}

multi method config ( Str:D $module, 'view', Str :$recman-name! )  {

  🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

  if $recman {

    🦋 qq[REC: ｢$recman-name｣];

    my Str $json = to-json $recman;

    out $json;

  } else {

    🐞 qq[REC: ｢$recman-name｣ does not exist!];

  }

}

multi method config ( Str:D $module, 'view', Str :$log-level!, Str :@option! )  {

  🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  my $level = quietly %!configuration{ $module }{ $log-level };

  if $level {

    🦋 qq[LOG: ｢$level｣];

    @option.map( -> $option { out to-json $level{ $option }:p } );

  } else {

    🐞 qq[LOG: ｢$log-level｣ does not exist!];

  }

}

multi method config ( Str:D $module, 'view', Str :$log-level! )  {

  🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  my $level = quietly %!configuration{ $module }{ $log-level };

  if $level {

    🦋 qq[LOG: ｢$log-level｣];

    my Str $json = to-json $level;

    out $json;

  } else {

    🐞 qq[LOG: ｢$log-level｣ does not exist!];

  }

}

multi method config ( Str:D $module, 'view', Str :@option! )  {

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  @option.map( -> $option { out to-json %!configuration{ $module }{ $option }:p } );

}

multi method config ( Str:D $module, 'view'  )  {

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;

  🦋 qq[CNF: ｢$module｣];

  my Str $json = to-json %!configuration{ $module };

  out $json;

}


multi method config ( Str:D $module, 'reset' )  {

 🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  %!configuration{ $module } = %!default-configuration{ $module };

  my Str $json = to-json %!configuration{ $module };

  🦋 "CNF: " ~ "｢$module｣" ~ "\n" ~ $json;

  self!write-config;
  
}

multi method config ( Str:D $module, 'unset' )  {

 🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  my Str $json = to-json %!configuration{ $module }:delete;

  🦋 "CNF: " ~ "｢$module｣" ~ "\n" ~ $json;

  self!write-config;
  
}

multi method config ( 'reset' ) {

  🐛 qq[CNF: ｢$!config-file｣];
  
  self!check-config-file-exists;

  %!configuration = %!default-configuration;

  self!write-config;
  
}

multi method config ( 'view' )  {

  🐛 qq[CNF: ｢$!config-file｣];

  self!check-config-file-exists;

  my Str $json = to-json %!configuration;

  out $json;

}

multi method config ( 'new' ) {

  🐛 qq[CNF: ｢$!config-file｣];
  
  if $!config-file.e {

    🐞 qq[CNF: ｢$!config-file｣ already exists!];

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

  $!config-file.dirname.IO.mkdir unless $!config-file.dirname.IO.e;

  %!configuration = %!default-configuration;

  self!write-config;
  
  🧚 qq[CNF: ｢$!config-file｣];
}

method !write-config ( ) {

  my Str:D $json = to-json %!configuration;

  $!config-file.spurt: $json;

  🐛 "CNF: " ~ "\n" ~ $json;
}

method !check-config-file-exists ( ) {

  unless $!config-file.e {

    🐞 "CNF: " ~ "｢$!config-file｣ does not exist! to create run: pakku config new";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

}

method configuration ( ) { %!configuration }

submethod BUILD ( IO :$!config-file! ) {

  %!default-configuration = from-json slurp %?RESOURCES<default-config.json>;

  %!configuration = from-json slurp $!config-file if $!config-file.e;

}

sub from-json ( Str $json --> Hash:D ) { Rakudo::Internals::JSON.from-json: $json }

sub to-json ( \obj, :$pretty = True  --> Str:D ) { Rakudo::Internals::JSON.to-json: obj, :$pretty, :sorted-keys; }
