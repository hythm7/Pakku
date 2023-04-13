unit class Pakku::Recman::Local;

has Str:D      $.name is required;
has IO::Path:D $.location is required;

method recommend ( ::?CLASS:D: :$spec! ) {

}

method search ( ::?CLASS:D: :$spec!, Int :$count ) {

}
