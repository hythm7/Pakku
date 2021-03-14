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


class X::Pakku::Add is X::Pakku {

  has $.dist;

  method message ( ) { "Add: ｢$!dist｣" }

}

