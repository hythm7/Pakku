use X::Pakku;

unit class X::Pakku::Meta;
  also is X::Pakku;

has $.meta;

method message ( ) { "MTA: ｢$!meta｣" }
