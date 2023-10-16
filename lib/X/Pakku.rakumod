use Pakku::Log;

class X::Pakku is Exception { }


class X::Pakku::Spec is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'SPC', :$!msg }

}


class X::Pakku::Meta is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'MTA', :$!msg }

}


class X::Pakku::Build is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'BLD', :$!msg }

}


class X::Pakku::Test is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'TST', :$!msg }

}

class X::Pakku::Stage is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'STG', :$!msg }

}

class X::Pakku::Add is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'ADD', :$!msg }


}

class X::Pakku::Remove is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'RMV', :$!msg }

}

class X::Pakku::Nuke is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'NUK', :$!msg }

}


class X::Pakku::Archive is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'ARC', :$!msg }

}

class X::Pakku::Update is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'UPD', :$!msg }

}


class X::Pakku::Native is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'NTV', :$!msg }

}


class X::Pakku::Cmd is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'CMD', :$!msg }

}

class X::Pakku::Cnf is X::Pakku {

  has Str:D $.msg is required;

  method message { log '🦗', header => 'CNF', :$!msg }

}
