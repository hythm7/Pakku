use Pakku::Log;

class X::Pakku {
  also is Exception;
}

class X::Pakku::Repo::CannotInstall {
  also is Exception;

  has Str $.repo;

  method message ( --> Str:D ) {

    "X:Repo: [$!repo] cannot Install";

  }
}

class X::Pakku::Ecosystem::Update {
  also is X::Pakku;

  has $.source;

  method message ( --> Str:D ) {

    "X:Eco: Cannot update source [$!source]";

  }

}

class X::Pakku::Ecosystem::NoCandy {
  also is X::Pakku;

  has $.spec;

  method message ( --> Str:D ) {

    "X:Eco: No candy for spec [$!spec]";

  }

}
