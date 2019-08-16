use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::RecMan;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;


has %!config;
has Pakku::RecMan $!recman;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );
  
  %!config = $cnf.ast.merge: $cmd.ast;

  $!recman = Pakku::RecMan.new: source => flat %!config<source>;
  

  given %!config<cmd> {

    self.add(    |%!config<add> )    when 'add';
    self.remove( |%!config<remove> ) when 'remove';
    self.search( |%!config<search> ) when 'search';

  }
 
}

method search ( :@dist! ) {

  $!recman.search: :@dist;

}

method add ( ) {

}

method remove ( ) {

}

