unit role Pakku::Help;

method help ( Str:D :$cmd ) {

  given $cmd {

    when 'add'    { put 'help add' }
    when 'remove' { put 'help remove' }
    when 'list'   { put 'help list' }

    default { put 'help' }

  }

}
