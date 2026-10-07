use Pakku::Log;

# Every Pakku exception carries a msg (what) and an optional comment (why);
# the three-letter header comes from the class name.
class X::Pakku is Exception {

  has Str:D $.msg     is required;
  has Str   $.comment;

  my constant %header =
    Spec    => 'SPC', Meta   => 'MTA', Build  => 'BLD', Test   => 'TST', Stage  => 'STG',
    Add     => 'ADD', Remove => 'RMV', Nuke   => 'NUK', Fetch  => 'FTC', Archive => 'ARC',
    Update  => 'UPD', Native => 'NTV', Cmd    => 'CMD', Cnf    => 'CNF', Index   => 'IDX';

  method header ( --> Str:D ) { %header{ self.^name.split( '::' ).tail } // 'ERR' }

  method message { log '🦗', header => self.header, :$!msg, |( :$!comment if $!comment ) }

}

class X::Pakku::Spec    is X::Pakku { }
class X::Pakku::Meta    is X::Pakku { }
class X::Pakku::Build   is X::Pakku { }
class X::Pakku::Test    is X::Pakku { }
class X::Pakku::Stage   is X::Pakku { }
class X::Pakku::Add     is X::Pakku { }
class X::Pakku::Remove  is X::Pakku { }
class X::Pakku::Nuke    is X::Pakku { }
class X::Pakku::Fetch   is X::Pakku { }
class X::Pakku::Archive is X::Pakku { }
class X::Pakku::Update  is X::Pakku { }
class X::Pakku::Native  is X::Pakku { }
class X::Pakku::Cmd     is X::Pakku { }
class X::Pakku::Cnf     is X::Pakku { }
class X::Pakku::Index   is X::Pakku { }
