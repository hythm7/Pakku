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

  has Str $.level;
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

multi method configure ( $module, :$recman-name!, Pair:D :@option! ) {

	self!check-config-file-exists;

	@option.map( -> $option { die X::Pakku::Cnf.new( cnf => $option ) unless self."$module"().new( |$option ) ~~ $option } );

	my $index = quietly %!config{ $module }.first( *.<name> eq $recman-name, :k );

	if defined $index {

	  @option.map( -> $option {
	    %!config{ $module }[ $index ]{ $option.key } = $option.value;
	  } );

	} else {

	   @option.prepend: ( name => $recman-name );

	   %!config{ $module }.unshift: @option.map( *.Pair ).hash;
	}

	self!write-config;

}

multi method configure ( $module, Pair:D :@option! ) {

	self!check-config-file-exists;

	@option.map( -> $option { die X::Pakku::Cnf.new( cnf => $option ) unless self."$module"().new( |$option ) ~~ $option } );

	@option.map( -> $option {
	    %!config{ $module }{ $option.key } = $option.value;
	  }
	);

	self!write-config;

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
