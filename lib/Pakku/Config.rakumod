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

has $!config-file is built;

has %!default-config;
has %!config;


multi method configure ( $module, Pair:D :@option!, Str :$recman-name, Str :$log-level ) {

	self!check-config-file-exists;

	# smart match against pair
	@option.map( -> $option { die X::Pakku::Cnf.new( cnf => $option ) unless try self."$module"().new( |$option ) ~~ $option } );

	my %config-key;

	given $module {

	  when 'recman' {

	    my $index = quietly %!config{ $module }.first( *.<name> eq $recman-name, :k );

	  	if defined $index {

        %config-key := %!config{ $module }[ $index ];

	  	} else {

        %!config{ $module }.unshift( { name => $recman-name } ); 

        %config-key := %!config{ $module }[ 0 ];

	  	}
	  }

		when 'log' { %config-key := %!config{ $module }{ $log-level } }

		default { %config-key := %!config{ $module } }

	}

	@option.map( -> $option {

    my $key   = $option.key;
    my $value = $option.value; 

    %config-key{ $key } = $value;

    %config-key{ $key }:delete without $value; # remove null values

	} );

	self!write-config;

}

multi method configure ( $module, 'unset', :$recman-name! ) {

  🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

	my $recman = quietly %!config{ $module }.first( *.<name> eq $recman-name );

	unless $recman {

	  🐞 REC ~ "$recman-name Does Not Exist!";

    die X::Pakku::Cnf.new: cnf => $recman-name; 

	}

  %!config{ $module } .= grep( not *.<name> eq $recman-name );

	self!write-config;

	quietly 🐛 CNF ~ $recman;

}

multi method configure ( $module, 'unset', :$log-level! ) {

  🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

	unless %!config{ $module }{ $log-level }:exists {

	  🐞 LOG ~ "$log-level Does Not Exist!";

    die X::Pakku::Cnf.new: cnf => $log-level; 

	}

	my $level = %!config{ $module }{ $log-level }:delete;

	self!write-config;

	quietly 🐛 CNF ~ $level;
}

multi method configure ( $module, 'view', :@option! )  {

  🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	@option.map( -> $option { out hash-to-json %!config{ $module }{ $option } } );

}

multi method configure ( $module, 'view' )  {

  🐛 CNF ~ "｢$!config-file｣";
	
  self!check-config-file-exists;

  my $module-json = hash-to-json %!config{ $module };

	out $module-json;
  
}


multi method configure ( $module, 'reset' )  {

 🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	%!config{ $module } = %!default-config{ $module };

	my $module-json = hash-to-json %!config{ $module };

	🐛 CNF ~ "\n" ~ $module-json;

	self!write-config;
	
	🧚 CNF ~ "｢$!config-file｣";
}

multi method configure ( 'reset' ) {

	🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

	%!config = %!default-config;
	self!write-config;
	
	🧚 CNF ~ "｢$!config-file｣";
}

multi method configure ( 'view' )  {

	🐛 CNF ~ "｢$!config-file｣";

	self!check-config-file-exists;

  my Str:D $json = hash-to-json %!config;

  out $json;

}

multi method configure ( 'new' ) {

  🐛 CNF ~ "｢$!config-file｣";
	
	if $!config-file.e {

		🐞 CNF ~ "$!config-file Already Exists!";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

	%!config = %!default-config;

	self!write-config;
	
	🧚 CNF ~ "｢$!config-file｣";
}

method !write-config ( ) {

  my Str:D $json = hash-to-json %!config;

	$!config-file.spurt: $json;

	🐛 CNF ~ "\n" ~ $json;
}

method !check-config-file-exists ( ) {

	unless $!config-file.e {

		🐞 CNF ~ "$!config-file Does Not Exist!";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

}

method config ( ) { %!config }

submethod TWEAK ( ) {

  %!default-config = json-to-hash slurp %?RESOURCES<default-config.json>;

  %!config = json-to-hash slurp $!config-file if $!config-file.e;

}

sub json-to-hash ( Str:D  $json --> Hash:D ) {  Rakudo::Internals::JSON.from-json: $json;                        }
sub hash-to-json (        \obj  --> Str:D  ) {  Rakudo::Internals::JSON.to-json:   obj, :pretty, :sorted-keys; }
