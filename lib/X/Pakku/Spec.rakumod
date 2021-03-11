use X::Pakku;

unit class X::Pakku::Spec;
  also is X::Pakku;

has $.spec;

method message ( ) { "SPC: ｢$!spec｣" }
