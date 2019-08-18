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

 
  given %!config<cmd> {

    my @source = flat %!config<pakku><source>;

    when 'add' {
      $!recman = Pakku::RecMan.new: :@source;
      self.add(    |%!config<add> );
    }

    when 'remove' {
      self.remove(    |%!config<remove> );
    }

    when 'search' {
      $!recman = Pakku::RecMan.new: :@source;
      self.search(    |%!config<search> );
    }

  }
 
}

method search ( :@ident! ) {

  $!recman.search: :@ident;

}

method add ( :@ident! ) {

  my @cand = $!recman.search: :@ident;

  CompUnit::Repository::Installation.new( prefix => '/tmp'.IO ).install(@cand.head);

  #say @cand;

}

method remove ( ) {

}

