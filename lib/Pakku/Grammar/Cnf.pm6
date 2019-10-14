
use Pakku::Grammar::Common;

grammar Pakku::Grammar::Cnf {
  also does Pakku::Grammar::Common;

  token TOP { <sections> }

  token sections { [ <.ws> | <.nl> ] <section>* }

  proto rule section { * }
  rule section:sym<pakku>  { <.ws> <.lt> <sym> <.gt> <.nl> <pakkuopt>*  %% <.eol> }
  rule section:sym<add>    { <.ws> <.lt> <sym> <.gt> <.nl> <addopt>*    %% <.eol> }
  rule section:sym<build>  { <.ws> <.lt> <sym> <.gt> <.nl> <buildopt>*  %% <.eol> }
  rule section:sym<test>   { <.ws> <.lt> <sym> <.gt> <.nl> <testopt>*   %% <.eol> }
  rule section:sym<remove> { <.ws> <.lt> <sym> <.gt> <.nl> <removeopt>* %% <.eol> }
  rule section:sym<list>   { <.ws> <.lt> <sym> <.gt> <.nl> <listopt>*   %% <.eol> }
  rule section:sym<source> { <.ws> <.lt> <sym> <.gt> <.nl> <sourceopt>* %% <.eol> }
  rule section:sym<log>    { <.ws> <.lt> <sym> <.gt> <.nl> <logopt>*    %% <.eol> }

  proto rule sourceopt { * }
  rule sourceopt:sym<source>  { <source>  }

  proto rule logopt { * }
  rule logopt:sym<name>  { <level> <sym> <level-name>  <.eol> }
  rule logopt:sym<color> { <level> <sym> <level-color> <.eol> }

  token level-name  { <-[\s]>+ }

  proto token level-color { * }
  token level-color:sym<reset>   { <sym> }
  token level-color:sym<default> { <sym> }
  token level-color:sym<black>   { <sym> }
  token level-color:sym<blue>    { <sym> }
  token level-color:sym<green>   { <sym> }
  token level-color:sym<yellow>  { <sym> }
  token level-color:sym<magenta> { <sym> }
  token level-color:sym<red>     { <sym> }

  token source { <-[<\n]>+ } # TODO use better token

  token eol { [ \h* [ <[#]> \N* ]? \n ]+ }

  token nl { [ <comment>? \h* \n ]+ }

  token comment { \h* '#' \N* }

  token ws  { \h* }

}

class Pakku::Grammar::Cnf::Actions {
  also does Pakku::Grammar::Common::Actions;

  has %!cnf;

  method TOP ( $/ ) { make %!cnf }

  method section:sym<pakku>  ( $/ ) { %!cnf{~$<sym>} = $<pakkuopt>».ast.hash }
  method section:sym<add>    ( $/ ) { %!cnf{~$<sym>} = $<addopt>».ast.hash }
  method section:sym<remove> ( $/ ) { %!cnf{~$<sym>} = $<removeopt>».ast.hash }
  method section:sym<list>   ( $/ ) { %!cnf{~$<sym>} = $<listopt>».ast.hash }
  method section:sym<source> ( $/ ) { %!cnf{~$<sym>}.append: $<sourceopt>».ast }

  method logopt:sym<name>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-name>;

  }

  method logopt:sym<color>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-color>;

  }

  method sourceopt:sym<source> ( $/ ) { make $<source>.Str }

}
