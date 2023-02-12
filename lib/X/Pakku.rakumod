class X::Pakku is Exception { }


class X::Pakku::Spec is X::Pakku {

  has $.spec;

  method message ( ) { "SPC: ｢$!spec｣" }

}


class X::Pakku::Meta is X::Pakku {

  has $.meta;

  method message ( ) { "MTA: ｢$!meta｣" }

}


class X::Pakku::Build is X::Pakku {

  has $.dist;

  method message ( ) { "BLD: ｢$!dist｣" }

}


class X::Pakku::Test is X::Pakku {

  has $.dist;

  method message ( ) { "TST: ｢$!dist｣" }

}


class X::Pakku::Stage is X::Pakku {

  has $.dist;

  method message ( ) { "STG: ｢$!dist｣" }

}

class X::Pakku::Add is X::Pakku {

  has $.dist;

  method message ( ) { "Add: ｢$!dist｣" }

}

class X::Pakku::Archive is X::Pakku {

  has $.download;

  method message ( ) { "ARC: ｢$!download｣" }

}

class X::Pakku::Upgrade is X::Pakku {

  has $.spec;

  method message ( ) { "UPG: ｢$!spec｣" }

}


class X::Pakku::Native is X::Pakku {

  has $.lib;

  method message ( ) { "NTV: ｢$!lib｣" }

}

class X::Pakku::Cmd is X::Pakku {
  also is Exception;

  has $.cmd;

  method message ( --> Str:D ) {

    "CMD: ｢$!cmd｣";

  }

}

class X::Pakku::Cnf is X::Pakku {
  also is Exception;

  has $.cnf;

  method message ( --> Str:D ) {

    "CNF: ｢$!cnf｣";

  }

}
