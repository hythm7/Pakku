use X::Pakku;
use Pakku::Log;

unit class Pakku::Config;


has $!config-file is built;

has %!default-config;
has %!config;

my class Pakku {

  has Bool $.pretty;
  has Bool $.async;
  has Bool $.recman;
  has Bool $.cache;
  has Bool $.yolo;
  has Bool $.please;
  has Bool $.dont;
	has Str()  $.verbose;

}

multi method configure ( 'pakku', 'enable', :@option! ) {

	self!check-config-file-exists;

	@option
		==> map( -> $option {  say Pakku.new: |Pair.new( $option, True )."$option"() });

  
}




# I dont need enable, disable, set, unset here
# if :opt enable, :!opt disable, opt => 'val', set, "opt" unset

multi method configure ( 'add',      'enable', :@option! )      { say 'add enable';  }
multi method configure ( 'upgrade',  'enable', :@option! )      { say 'upgrade enable';  }
multi method configure ( 'remove',   'enable', :@option! )      { say 'remove enable';  }
multi method configure ( 'build',    'enable', :@option! )      { say 'build enable';  }
multi method configure ( 'test',     'enable', :@option! )      { say 'test enable';  }
multi method configure ( 'list',     'enable', :@option! )      { say 'list enable';  }
multi method configure ( 'search',   'enable', :@option! )      { say 'search enable';  }
multi method configure ( 'download', 'enable', :@option! )      { say 'download enable';  }
multi method configure ( 'recman',   'enable', :$recman-name! ) { say "recman $recman-name enable";  }

multi method configure ( 'pakku',    'disable', :@option! )      { say 'pakku disable';  }
multi method configure ( 'add',      'disable', :@option! )      { say 'add disable';  }
multi method configure ( 'upgrade',  'disable', :@option! )      { say 'upgrade disable';  }
multi method configure ( 'remove',   'disable', :@option! )      { say 'remove disable';  }
multi method configure ( 'build',    'disable', :@option! )      { say 'build disable';  }
multi method configure ( 'test',     'disable', :@option! )      { say 'test disable';  }
multi method configure ( 'list',     'disable', :@option! )      { say 'list disable';  }
multi method configure ( 'search',   'disable', :@option! )      { say 'search disable';  }
multi method configure ( 'download', 'disable', :@option! )      { say 'download disable';  }
multi method configure ( 'recman',   'disable', :$recman-name! ) { say "recman $recman-name disable";  }

multi method configure ( 'pakku',    'set', :@option! )      { say 'pakku set';  }
multi method configure ( 'add',      'set', :@option! )      { say 'add set';  }
multi method configure ( 'upgrade',  'set', :@option! )      { say 'upgrade set';  }
multi method configure ( 'remove',   'set', :@option! )      { say 'remove set';  }
multi method configure ( 'build',    'set', :@option! )      { say 'build set';  }
multi method configure ( 'test',     'set', :@option! )      { say 'test set';  }
multi method configure ( 'list',     'set', :@option! )      { say 'list set';  }
multi method configure ( 'search',   'set', :@option! )      { say 'search set';  }
multi method configure ( 'download', 'set', :@option! )      { say 'download set';  }
multi method configure ( 'recman',   'set', :$recman-name!, :@option! ) { say "recman $recman-name set";  }
multi method configure ( 'log',      'set', :$log-level!, :@option! ) { say "log $log-level set";  }

multi method configure ( 'pakku',    'unset', :@option! )      { say 'pakku unset';  }
multi method configure ( 'add',      'unset', :@option! )      { say 'add unset';  }
multi method configure ( 'upgrade',  'unset', :@option! )      { say 'upgrade unset';  }
multi method configure ( 'remove',   'unset', :@option! )      { say 'remove unset';  }
multi method configure ( 'build',    'unset', :@option! )      { say 'build unset';  }
multi method configure ( 'test',     'unset', :@option! )      { say 'test unset';  }
multi method configure ( 'list',     'unset', :@option! )      { say 'list unset';  }
multi method configure ( 'search',   'unset', :@option! )      { say 'search unset';  }
multi method configure ( 'download', 'unset', :@option! )      { say 'download unset';  }
multi method configure ( 'recman',   'unset', :$recman-name!, :@option! ) { say "recman $recman-name unset";  }
multi method configure ( 'log',      'unset', :$log-level!, :@option! ) { say "log $log-level unset";  }



my class Add {

  has Any  $.deps;
  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.force;
  has Bool $.precompile;
	has Str  $.to;
	has Str  @.exclude;

}

my class Upgrade {

  has Any  $.deps;
  has Bool $.build;
  has Bool $.test;
  has Bool $.xtest;
  has Bool $.force;
  has Bool $.precompile;
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

  has Bool $.details;
  has Int  $.count;

}

my class Recman {

  has Str $.name;
  has Int $.priority;
  has Str $.url;

}

my class Log {

  has Str $.level;
  has Any $.color;
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

  my Str:D $json = hash-to-json %!config;

	$!config-file.spurt: $json;
	
	🧚 CNF ~ "｢$!config-file｣";
}

multi method configure ( 'reset' ) {

	🐛 CNF ~ "｢$!config-file｣";
	
	self!check-config-file-exists;

  my Str:D $json = hash-to-json %!default-config;

	$!config-file.spurt: $json;
	
	🐛 CNF ~ "\n" ~ $json;

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

  my Str:D $json = hash-to-json %!default-config;

	$!config-file.spurt: $json;
	
	🐛 CNF ~ "\n" ~ $json;

	🧚 CNF ~ "｢$!config-file｣";
}

method !check-config-file-exists ( ) {

	unless $!config-file.e {

		🐞 CNF ~ "$!config-file Does Not Exist!";

    die X::Pakku::Cnf.new: cnf => $!config-file; 

  }

}


submethod TWEAK ( ) {

  %!default-config = json-to-hash slurp %?RESOURCES<default-config.json>;

  %!config = json-to-hash slurp $!config-file if $!config-file.e;

}

sub json-to-hash ( Str:D  $json --> Hash:D ) {  Rakudo::Internals::JSON.from-json: $json;                        }
sub hash-to-json (        \obj  --> Str:D  ) {  Rakudo::Internals::JSON.to-json:   obj, :pretty, :sorted-keys; }
