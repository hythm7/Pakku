use X::Pakku;

unit class X::Pakku::Build;
  also is X::Pakku;

has $.dist;

method message ( ) { "BLD: ｢$!dist｣" }
