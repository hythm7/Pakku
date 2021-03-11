use X::Pakku;

unit class X::Pakku::Add;
  also is X::Pakku;

has $.dist;

method message ( ) { "ADD: ｢$!dist｣" }
