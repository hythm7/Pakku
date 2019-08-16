#no precompilation;
#use Grammar::Tracer;

grammar Pakku::Grammar::Cnf {

  token TOP { <sections> }

  token sections { <.ws> <section>* }

  proto rule section { * }
  rule section:sym<add>    { <lt> <sym> <gt> <.nl> <addopt>+    }
  rule section:sym<remove> { <lt> <sym> <gt> <.nl> <removeopt>+ }
  rule section:sym<source> { <lt> <sym> <gt> <.nl> <source>+    }

  proto rule addopt { * }
  rule addopt:sym<deps> { <.ws> <deps> <.eol> }
  rule addopt:sym<test> { <.ws> <test> <.eol> }
  rule addopt:sym<yolo> { <.ws> <yolo> <.eol> }
  rule addopt:sym<into> { <.ws> <into> <path> <.eol> }

  proto rule removeopt { * }
  rule removeopt:sym<deps> { <.ws> <deps> <.eol> }
  rule removeopt:sym<yolo> { <.ws> <yolo> <.eol> }
  rule removeopt:sym<from> { <.ws> <from> <path> <.eol> }

  proto token deps { * }
  token deps:sym<deps>   { «<sym>» }
  token deps:sym<d>      { «<sym>» }
  token deps:sym<nodeps> { «<sym>» }
  token deps:sym<nd>     { «<sym>» }

  proto token test { * }
  token test:sym<test>   { «<sym>» }
  token test:sym<t>      { «<sym>» }
  token test:sym<notest> { «<sym>» }
  token test:sym<nt>     { «<sym>» }

  proto token yolo { * }
  token yolo:sym<yolo> { «<sym>» }
  token yolo:sym<y>    { «<sym>» }

  proto token into { * }
  token into:sym<into> { «<sym>» }

  proto token from { * }
  token from:sym<from> { «<sym>» }


  token source { <.ws> $<url>=<-[\n]>* <.eol> }
  token path { <[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+ }

  token eol { [ [ <[#;]> \N* ]? \n ]+ }

  token nl { [ <comment>? \h* \n ]+ }

  token comment { \h* '#' \N* }

  token lt  { '<' }
  token gt  { '>' }
  token ws  { \h* }

}

class Pakku::Grammar::Cnf::Actions {

  method TOP ( $/ ) { make $<sections>.ast }

  method sections ( $/ ) { make $<section>».ast.hash }

  method section:sym<add>    ( $/ ) { make ~$<sym> => $<addopt>».ast.hash }
  method section:sym<remove> ( $/ ) { make ~$<sym> => $<removeopt>».ast.hash }
  method section:sym<source> ( $/ ) { make ~$<sym> => $<source>».ast }

  method addopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method addopt:sym<test> ( $/ ) { make $<test>.ast }
  method addopt:sym<into> ( $/ ) { make ( into => $<path>.IO )  }
  method addopt:sym<yolo> ( $/ ) { make ( :yolo )  }

  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) { make ( from => $<path>.IO )  }
  method removeopt:sym<yolo> ( $/ ) { make ( :yolo )  }

  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }

  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

  method source     ( $/ )  { make $<url>.Str }
}
