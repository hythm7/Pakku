#no precompilation;
#use Grammar::Tracer;

grammar Pakku::Grammar::Cnf {

  token TOP { <sections> }

  token sections { <.ws> <section>* }

  proto rule section { * }
  rule section:sym<pakku>  { <lt> <sym> <gt> <.nl> <pakkuopt>+  }
  rule section:sym<add>    { <lt> <sym> <gt> <.nl> <addopt>+    }
  rule section:sym<remove> { <lt> <sym> <gt> <.nl> <removeopt>+ }
  rule section:sym<search> { <lt> <sym> <gt> <.nl> <searchopt>+    }

  proto rule pakkuopt { * }
  rule pakkuopt:sym<yolo>    { <.ws> <yolo>    <.eol> }
  rule pakkuopt:sym<force>   { <.ws> <force>   <.eol> }
  rule pakkuopt:sym<verbose> { <.ws> <verbose> <.eol> }
  rule pakkuopt:sym<repo>    { <.ws> <repo>    <reponame> <.eol> }
  rule pakkuopt:sym<source>  { <.ws> <sym>     <source>   <.eol> }

  proto rule addopt { * }
  rule addopt:sym<deps> { <.ws> <deps> <.eol> }
  rule addopt:sym<test> { <.ws> <test> <.eol> }
  rule addopt:sym<into> { <.ws> <into> <reponame> <.eol> }

  proto rule removeopt { * }
  rule removeopt:sym<deps> { <.ws> <deps> <.eol> }
  rule removeopt:sym<from> { <.ws> <from> <reponame> <.eol> }

  proto rule searchopt { * }
  rule searchopt:sym<deps> { <.ws> <deps> <.eol> }

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

  proto token repo { * }
  token repo:sym<repo> { «<sym>» }

  proto token reponame { * }
  token reponame:sym<home>    { «<sym>» }
  token reponame:sym<site>    { «<sym>» }
  token reponame:sym<verndor> { «<sym>» }

  proto token yolo { * }
  token yolo:sym<yolo> { «<sym>» }
  token yolo:sym<y>    { «<sym>» }

  proto token force { * }
  token force:sym<force> { «<sym>» }
  token force:sym<f>     { «<sym>» }

  proto token verbose { * }
  token verbose:sym<verbose> { «<sym>» }
  token verbose:sym<v>       { «<sym>» }

  proto token into { * }
  token into:sym<into> { «<sym>» }

  proto token from { * }
  token from:sym<from> { «<sym>» }


  token source { $<url>=<-[\n]>+ }
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

  method section:sym<pakku>  ( $/ ) { make ~$<sym> => $<pakkuopt>».ast.hash }
  method section:sym<add>    ( $/ ) { make ~$<sym> => $<addopt>».ast.hash }
  method section:sym<remove> ( $/ ) { make ~$<sym> => $<removeopt>».ast.hash }
  method section:sym<search> ( $/ ) { make ~$<sym> => $<searchopt>».ast.hash }

   method pakkuopt:sym<repo>    ( $/ ) {
    my $repo = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<repo> => $repo;
  }
  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )  }
  method pakkuopt:sym<force>   ( $/ ) { make ( :force )  }
  method pakkuopt:sym<verbose> ( $/ ) { make ( :verbose )  }
  method pakkuopt:sym<source>  ( $/ ) { make ( $<sym>.Str => $<source>.ast )  }

  method addopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method addopt:sym<test> ( $/ ) { make $<test>.ast }
  method addopt:sym<from> ( $/ ) {
    my $into = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<into> => $into;
  }


  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) {
    my $from = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<from> => $from;
  }

  method searchopt:sym<deps> ( $/ ) { make $<deps>.ast }

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
