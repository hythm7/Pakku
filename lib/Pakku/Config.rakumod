use X::Pakku;
use Pakku::Log;

unit class Pakku::Config;

my class Pakku {

  has Bool $.pretty;
  has Bool $.async;
  has Bool $.recman;
  has Bool $.cache;
  has Bool $.yolo;
  has Bool $.please;
  has Bool $.dont;
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

my class Upgrade {

  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.force;
  has Bool $.precompile;
  has Any  $.deps;
	has Str  $.in;
	has Str  @.exclude;

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
  has Int() $.count;

}

my class Recman {

  has Str   $.name;
  has Str   $.url;
  has Int() $.priority;
  has Bool  $.active;

}

my class Log {

  has Str $.prefix;
  has Any $.color;

}

has Pakku    $.pakku;
has Add      $.add;
has Upgrade  $.upgrade;
has Search   $.search;
has Remove   $.remove;
has Build    $.build;
has Test     $.test;
has List     $.list;
has Download $.download;
has Recman   $.recman;
has Log      $.log;

has $!config-file;

has %!default-configuration;
has %!configuration;


multi method config ( Str:D $module, Pair:D :@option!, Str :$recman-name, Str :$log-level ) {

  🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

	# smart match against pair
	@option.map( -> $option {

	  unless try self."$module"().new( |$option ) ~~ $option {

		🐞 CNF ~ "｢{ hash-to-json $option, :!pretty }｣ invalid option";

	    die X::Pakku::Cnf.new( cnf => "$module" );
	  }

	} );

	my %config-key;

	🦋 CNF ~ "｢$module｣";

	given $module {

	  when 'recman' {

      🦋 REC  ~ "｢$recman-name｣";

	    my $index = quietly %!configuration{ $module }.first( *.<name> eq $recman-name, :k );

	  	if defined $index {

        %config-key := %!configuration{ $module }[ $index ];

	  	} else {

        %!configuration{ $module }.unshift( { name => $recman-name, :active } ); 

        %config-key := %!configuration{ $module }[ 0 ];

	  	}
	  }

		when 'log' {

      🦋 LOG  ~ "｢$log-level｣";

		  %config-key := %!configuration{ $module }{ $log-level }

		}

		default { %config-key := %!configuration{ $module } }

	}

	@option.map( -> $option {

    my $key   = $option.key;
    my $value = $option.value; 

    %config-key{ $key } = $value;

    %config-key{ $key }:delete without $value; # remove null values

    🦋 CNF ~ "｢{ hash-to-json $option, :!pretty }｣";

	} );

	self!write-config;

}

multi method config ( Str:D $module, 'unset', :$recman-name! ) {

  🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

	my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

	🐞 LOG ~ "｢$recman-name｣ does not exist!" unless $recman;

	quietly 🦋 CNF ~ "｢$recman-name｣" ~ "\n" ~ hash-to-json $recman with $recman;

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

  🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;


	🐞 LOG ~ "｢$log-level｣ does not exist!" unless %!configuration{ $module }{ $log-level }:exists;

  my $level = %!configuration{ $module }{ $log-level }:delete;

	quietly 🦋 CNF ~ "｢$log-level｣" ~ "\n" ~ hash-to-json $level with $level;

	self!write-config;
}

multi method config ( Str:D $module, 'view', Str :$recman-name!, Str :@option! )  {

  🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	🦋 CNF ~ "｢$module｣";

	my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

  if $recman {

	  🦋 REC ~ "｢$recman-name｣";

	  @option.map( -> $option { out hash-to-json $recman{ $option }:p } );

  } else {

	  🐞 REC ~ "｢$recman-name｣ does not exist!";

  }

}

multi method config ( Str:D $module, 'view', Str :$recman-name! )  {

  🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	🦋 CNF ~ "｢$module｣";

	my $recman = quietly %!configuration{ $module }.first( *.<name> eq $recman-name );

  if $recman {

	  🦋 REC ~ "｢$recman-name｣";

    my Str $json = hash-to-json $recman;

    out $json;

  } else {

	  🐞 REC ~ "｢$recman-name｣ does not exist!";

  }

}

multi method config ( Str:D $module, 'view', Str :$log-level!, Str :@option! )  {

  🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	🦋 CNF ~ "｢$module｣";

	my $level = quietly %!configuration{ $module }{ $log-level };

  if $level {

	  🦋 LOG ~ "｢$level｣";

	  @option.map( -> $option { out hash-to-json $level{ $option }:p } );

  } else {

	  🐞 LOG ~ "｢$log-level｣ does not exist!";

  }

}

multi method config ( Str:D $module, 'view', Str :$log-level! )  {

  🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	🦋 CNF ~ "｢$module｣";

	my $level = quietly %!configuration{ $module }{ $log-level };

  if $level {

	  🦋 LOG ~ "｢$log-level｣";

    my Str $json = hash-to-json $level;

    out $json;

  } else {

	  🐞 LOG ~ "｢$log-level｣ does not exist!";

  }

}

multi method config ( Str:D $module, 'view', Str :@option! )  {

  🐛 CNF ~ "｢$!config-file｣";

  self!check-config-file-exists;

  🦋 CNF ~ "｢$module｣";

	@option.map( -> $option { out hash-to-json %!configuration{ $module }{ $option }:p } );

}

multi method config ( Str:D $module, 'view'  )  {

  🐛 CNF ~ "｢$!config-file｣";

  self!check-config-file-exists;

  🦋 CNF ~ "｢$module｣";

  my Str $json = hash-to-json %!configuration{ $module };

  out $json;

}


multi method config ( Str:D $module, 'reset' )  {

 🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	%!configuration{ $module } = %!default-configuration{ $module };

	my Str $json = hash-to-json %!configuration{ $module };

	🦋 CNF ~ "｢$module｣" ~ "\n" ~ $json;

	self!write-config;
	
}

multi method config ( Str:D $module, 'unset' )  {

 🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

  my Str $json = hash-to-json %!configuration{ $module }:delete;

	🦋 CNF ~ "｢$module｣" ~ "\n" ~ $json;

	self!write-config;
	
}

multi method config ( 'reset' ) {

	🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	%!configuration = %!default-configuration;

	self!write-config;
	
}

multi method config ( 'view' )  {

	🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

  my Str $json = hash-to-json %!configuration;

  out $json;

}

multi method config ( 'new' ) {

  🐛 CNF ~ "｢$!config-file｣";
	
	if $!config-file.e {

		🐞 CNF ~ "｢$!config-file｣ already exists!";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

	%!configuration = %!default-configuration;

	self!write-config;
	
	🧚 CNF ~ "｢$!config-file｣";
}

method !write-config ( ) {

  my Str:D $json = hash-to-json %!configuration;

	$!config-file.spurt: $json;

	🐛 CNF ~ "\n" ~ $json;
}

method !check-config-file-exists ( ) {

	unless $!config-file.e {

		🐞 CNF ~ "｢$!config-file｣ does not exist!";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

}

method configuration ( ) { %!configuration }

submethod BUILD ( IO :$!config-file! ) {

  %!default-configuration = json-to-hash slurp %?RESOURCES<default-config.json>;

  %!configuration = json-to-hash slurp $!config-file if $!config-file.e;

}

sub json-to-hash ( Str $json --> Hash:D ) { Rakudo::Internals::JSON.from-json: $json }

sub hash-to-json ( \obj, :$pretty = True  --> Str:D ) { Rakudo::Internals::JSON.to-json: obj, :$pretty, :sorted-keys; }
