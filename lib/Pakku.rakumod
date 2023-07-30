use Pakku::Log;
use Pakku::Core;
use Pakku::Add;
use Pakku::Test;
use Pakku::Build;
use Pakku::Remove;
use Pakku::List;
use Pakku::Search;
use Pakku::Download;
use Pakku::State;
use Pakku::Update;
use Pakku::Config;
use Pakku::Help;

unit class Pakku;
  also does Pakku::Core;
  also does Pakku::Add;
  also does Pakku::Test;
  also does Pakku::Build;
  also does Pakku::Remove;
  also does Pakku::List;
  also does Pakku::Search;
  also does Pakku::Download;
  also does Pakku::State;
  also does Pakku::Update;
  also does Pakku::Config;
  also does Pakku::Help;

proto method fly ( | ) {

  {*}

  LEAVE self.clear;

  CATCH {
    when X::Pakku { 🦗 .message; .resume if $!yolo; nofun }
    default       { 🦗 .gist;                       nofun }
  }
}

multi method fly ( ) {

  LEAVE self.clear;

  self.clear;

  samewith %!cnf<cmd>, |%!cnf{ %!cnf<cmd> };

  ofun
}
