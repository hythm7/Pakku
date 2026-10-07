use Pakku::Log;
use Pakku::Core;
use Pakku::Command::Add;
use Pakku::Command::List;
use Pakku::Command::Test;
use Pakku::Command::Build;
use Pakku::Command::Search;
use Pakku::Command::Remove;
use Pakku::Command::State;
use Pakku::Command::Update;
use Pakku::Command::Download;
use Pakku::Command::Nuke;
use Pakku::Command::Config;
use Pakku::Command::Help;
use Pakku::Command::Refresh;

unit class Pakku;
  also does Pakku::Core;
  also does Pakku::Command::Add;
  also does Pakku::Command::List;
  also does Pakku::Command::Test;
  also does Pakku::Command::Build;
  also does Pakku::Command::Search;
  also does Pakku::Command::Remove;
  also does Pakku::Command::State;
  also does Pakku::Command::Update;
  also does Pakku::Command::Download;
  also does Pakku::Command::Nuke;
  also does Pakku::Command::Config;
  also does Pakku::Command::Help;
  also does Pakku::Command::Refresh;

# every command; an error ends the run with exit 1, after the temporary directories are gone (C4)
proto method fly ( | ) {

  {*}

  CATCH {

    when X::Pakku {
      .log;
      self.clear;
      nofun;
      exit 1;
    }

    default {
      log '🦗', header => 'ERR', msg => .gist, :!msg-delimit;
      self.clear;
      nofun;
      exit 1;
    }
  }
}

multi method fly ( ) {

  self.clear;

  my $cmd = %!cnf<cmd>;

  samewith $cmd, |%!cnf{ $cmd };

  self.clear;

  ofun;

}
