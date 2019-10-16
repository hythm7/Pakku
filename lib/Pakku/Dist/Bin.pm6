use Pakku::Dist;

unit class Pakku::Dist::Bin;
  also is Pakku::Dist;


has $.name;

method deps ( ) {

  Empty;

}

method gist ( Pakku::Dist::Bin:D: --> Str:D ) {

  $.name;

}

