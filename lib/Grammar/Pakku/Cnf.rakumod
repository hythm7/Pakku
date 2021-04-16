use Grammar::Pakku::Common;

class X::Pakku::Cnf {
  also is Exception;

  has $.cnf;

  method message ( --> Str:D ) {

    "CNF: ｢$!cnf｣";

  }

}

grammar Grammar::Pakku::Cnf {
  also does Grammar::Pakku::Common;

  token TOP { <sections> }

  token sections { [ <.ws> | <.nl> ] <section>* }

  proto rule section { * }
  rule section:sym<pakku>  { <.ws> <.lt> <sym> <.gt> <.nl> <pakkuopt>*  %% <.eol> }
  rule section:sym<add>    { <.ws> <.lt> <sym> <.gt> <.nl> <addopt>*    %% <.eol> }
  rule section:sym<build>  { <.ws> <.lt> <sym> <.gt> <.nl> <buildopt>*  %% <.eol> }
  rule section:sym<test>   { <.ws> <.lt> <sym> <.gt> <.nl> <testopt>*   %% <.eol> }
  rule section:sym<remove> { <.ws> <.lt> <sym> <.gt> <.nl> <removeopt>* %% <.eol> }
  rule section:sym<pack>    { <.ws> <.lt> <sym> <.gt> <.nl> <packopt>*    %% <.eol> }
  rule section:sym<list>   { <.ws> <.lt> <sym> <.gt> <.nl> <listopt>*   %% <.eol> }
  rule section:sym<search> { <.ws> <.lt> <sym> <.gt> <.nl> <searchopt>*   %% <.eol> }
  rule section:sym<recman> { <.ws> <.lt> <sym> <.gt> <.nl> <recmanopt>* %% <.eol> }
  rule section:sym<log>    { <.ws> <.lt> <sym> <.gt> <.nl> <logopt>*    %% <.eol> }

  proto rule recmanopt { * }
  rule recmanopt:sym<recman>  { <url>  }

  proto rule logopt { * }
  rule logopt:sym<prefix> { <level> <sym> <level-prefix>  }
  rule logopt:sym<color>  { <level> <sym> <level-color>   }

  token level-prefix  { <-[\s]>+ }

  proto token level-color { * }
  token level-color:sym<reset>   { <sym> }
  token level-color:sym<default> { <sym> }
  token level-color:sym<black>   { <sym> }
  token level-color:sym<blue>    { <sym> }
  token level-color:sym<green>   { <sym> }
  token level-color:sym<yellow>  { <sym> }
  token level-color:sym<magenta> { <sym> }
  token level-color:sym<red>     { <sym> }

  token url { <-[<\n]>+ } # TODO use better token

  token eol { [ \h* [ <[#]> \N* ]? \n ]+ }

  token nl { [ <comment>? \h* \n ]+ }

  token comment { \h* '#' \N* }

  token ws  { \h* }

}

class Grammar::Pakku::CnfActions {
  also does Grammar::Pakku::CommonActions;

  has %!cnf;

  method TOP ( $/ ) { make %!cnf }

  method section:sym<pakku>  ( $/ ) { %!cnf{~$<sym>} = $<pakkuopt>».made.hash }
  method section:sym<add>    ( $/ ) { %!cnf{~$<sym>} = $<addopt>».made.hash }
  method section:sym<remove> ( $/ ) { %!cnf{~$<sym>} = $<removeopt>».made.hash }
  method section:sym<pack>   ( $/ ) { %!cnf{~$<sym>} = $<packopt>».made.hash }
  method section:sym<list>   ( $/ ) { %!cnf{~$<sym>} = $<listopt>».made.hash }
  method section:sym<search> ( $/ ) { %!cnf{~$<sym>} = $<searchopt>».made.hash }
  method section:sym<recman> ( $/ ) { %!cnf{~$<sym>}.append: $<recmanopt>».made }

  method logopt:sym<prefix>    ( $/ ) {

    %!cnf<log><level>{$<level>.made}{~$<sym>} = ~$<level-prefix>;

  }

  method logopt:sym<color>    ( $/ ) {

    %!cnf<log><level>{$<level>.made}{~$<sym>} = ~$<level-color>;

  }

  method recmanopt:sym<recman> ( $/ ) { make $<url>.Str }

}
