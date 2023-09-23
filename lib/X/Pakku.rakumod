class X::Pakku is Exception { }


class X::Pakku::Spec is X::Pakku {

  has $.spec;

  method message ( ) { ~$!spec }

}


class X::Pakku::Meta is X::Pakku {

  has $.meta;

  method message ( ) { ~$!meta }

}


class X::Pakku::Build is X::Pakku {

  has $.dist;

  method message ( ) { ~$!dist }

}


class X::Pakku::Test is X::Pakku {

  has $.dist;

  method message ( ) { ~$!dist }

}

class X::Pakku::Stage is X::Pakku {

  has $.dist;

  method message ( ) { ~$!dist }

}

class X::Pakku::Add is X::Pakku {

  has $.dist;

  method message ( ) { ~$!dist }

}

class X::Pakku::Remove is X::Pakku {

  has $.spec;

  method message ( ) { ~$!spec }

}

class X::Pakku::Nuke is X::Pakku {

  has $.dir;

  method message ( ) { ~$!dir }

}


class X::Pakku::Archive is X::Pakku {

  has $.archive;

  method message ( ) { ~$!archive }

}

class X::Pakku::Update is X::Pakku {

  has $.spec;

  method message ( ) { ~$!spec }

}


class X::Pakku::Native is X::Pakku {

  has $.lib;

  method message ( ) { ~$!lib }

}


class X::Pakku::Cmd is X::Pakku {

  has $.cmd;

  method message ( --> Str:D ) { ~$!cmd; }

}

class X::Pakku::Cnf is X::Pakku {

  has $.cnf;

  method message ( --> Str:D ) {

    ~$!cnf;

  }

}
