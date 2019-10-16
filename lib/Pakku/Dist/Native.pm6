use Pakku::Dist;

unit class Pakku::Dist::Native;
  also is Pakku::Dist;


has $.name;

method deps ( ) {

  Empty;

}

method gist ( Pakku::Dist::Native:D: --> Str:D ) {

  $.name;

}

