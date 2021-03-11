use X::Pakku;

unit class X::Pakku::Test;
  also is X::Pakku;

has $.dist;

method message ( ) { "TST: ｢$!dist｣" }
