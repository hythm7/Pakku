#no precompilation;
#use Grammar::Tracer;

grammar Pakku::Grammar::Cnf {

  token TOP { <sections> }

  token sections { <.ws> <section>* }

  proto rule section { * }
  rule section:sym<pakku>  { <lt> <sym> <gt> <.nl> <pakkuopt>+  }
  rule section:sym<add>    { <lt> <sym> <gt> <.nl> <addopt>+    }
  rule section:sym<remove> { <lt> <sym> <gt> <.nl> <removeopt>+ }
  rule section:sym<search> { <lt> <sym> <gt> <.nl> <searchopt>+ }
  rule section:sym<source> { <lt> <sym> <gt> <.nl> <sourceopt>+ }
  rule section:sym<log>    { <lt> <sym> <gt> <.nl> <logopt>+    }

  proto rule pakkuopt { * }
  rule pakkuopt:sym<yolo>    { <.ws> <yolo>    <.eol> }
  rule pakkuopt:sym<force>   { <.ws> <force>   <.eol> }
  rule pakkuopt:sym<verbose> { <.ws> <verbose> <.eol> }
  rule pakkuopt:sym<repo>    { <.ws> <repo>    <reponame> <.eol> }

  proto rule addopt { * }
  rule addopt:sym<deps> { <.ws> <deps> <.eol> }
  rule addopt:sym<test> { <.ws> <test> <.eol> }
  rule addopt:sym<into> { <.ws> <into> <reponame> <.eol> }

  proto rule removeopt { * }
  rule removeopt:sym<deps> { <.ws> <deps> <.eol> }
  rule removeopt:sym<from> { <.ws> <from> <reponame> <.eol> }

  proto rule searchopt { * }
  rule searchopt:sym<deps> { <.ws> <deps> <.eol> }

  proto rule sourceopt { * }
  rule sourceopt:sym<source>  { <.ws> <source> <.eol> }

  proto rule logopt { * }
  rule logopt:sym<name>  { <.ws> <level> <sym> <level-name>  <.eol> }
  rule logopt:sym<color> { <.ws> <level> <sym> <level-color> <.eol> }

  token level-name  { <-[\s]>+ }

  proto token level-color { * } 
  token level-color:sym<reset>   { «<sym>» }
  token level-color:sym<default> { «<sym>» }
  token level-color:sym<black>   { «<sym>» }
  token level-color:sym<blue>    { «<sym>» }
  token level-color:sym<green>   { «<sym>» }
  token level-color:sym<yellow>  { «<sym>» }
  token level-color:sym<magenta> { «<sym>» }
  token level-color:sym<red>     { «<sym>» }

  proto token level { * }
  token level:sym<TRACE> { «<sym>» }
  token level:sym<DEBUG> { «<sym>» }
  token level:sym<INFO>  { «<sym>» }
  token level:sym<WARN>  { «<sym>» }
  token level:sym<ERROR> { «<sym>» }
  token level:sym<FATAL> { «<sym>» }
  token level:sym<trace> { «<sym>» }
  token level:sym<debug> { «<sym>» }
  token level:sym<info>  { «<sym>» }
  token level:sym<warn>  { «<sym>» }
  token level:sym<error> { «<sym>» }
  token level:sym<fatal> { «<sym>» }
  token level:sym<42>    { «<sym>» }
  token level:sym<T>     { «<sym>» }
  token level:sym<D>     { «<sym>» }
  token level:sym<I>     { «<sym>» }
  token level:sym<W>     { «<sym>» }
  token level:sym<E>     { «<sym>» }
  token level:sym<F>     { «<sym>» }
  token level:sym<1>     { «<sym>» }
  token level:sym<2>     { «<sym>» }
  token level:sym<3>     { «<sym>» }
  token level:sym<4>     { «<sym>» }
  token level:sym<5>     { «<sym>» }
  token level:sym<6>     { «<sym>» }
  token level:sym<🦋>     { «<sym>» }
  token level:sym<✗>     { «<sym>» }


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


  token source { <-[<\n]>+ } # TODO use better token
  token path { <[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+ }

  token eol { [ [ <[#;]> \N* ]? \n ]+ }

  token nl { [ <comment>? \h* \n ]+ }

  token comment { \h* '#' \N* }

  token lt  { '<' }
  token gt  { '>' }
  token ws  { \h* }

}

class Pakku::Grammar::Cnf::Actions {

  has %!cnf;

  method TOP ( $/ ) { make %!cnf }

  method section:sym<pakku>  ( $/ ) { %!cnf{~$<sym>} = $<pakkuopt>».ast.hash }
  method section:sym<add>    ( $/ ) { %!cnf{~$<sym>} = $<addopt>».ast.hash }
  method section:sym<remove> ( $/ ) { %!cnf{~$<sym>} = $<removeopt>».ast.hash }
  method section:sym<search> ( $/ ) { %!cnf{~$<sym>} = $<searchopt>».ast.hash }
  method section:sym<source> ( $/ ) { %!cnf{~$<sym>}.append: $<sourceopt>».ast }

  method logopt:sym<name>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-name>;

  }

  method logopt:sym<color>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-color>;

  }

   method pakkuopt:sym<repo>    ( $/ ) {

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<repo> => $repo;

  }
  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )  }
  method pakkuopt:sym<force>   ( $/ ) { make ( :force )  }
  method pakkuopt:sym<verbose> ( $/ ) { make ( :verbose )  }

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

  method sourceopt:sym<source> ( $/ ) { make $<source>.ast }

  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }

  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

  method source     ( $/ )  { make $/.Str }

  method level:sym<TRACE> ( $/ ) { make 1 }
  method level:sym<DEBUG> ( $/ ) { make 2 }
  method level:sym<INFO>  ( $/ ) { make 3 }
  method level:sym<WARN>  ( $/ ) { make 4 }
  method level:sym<ERROR> ( $/ ) { make 5 }
  method level:sym<FATAL> ( $/ ) { make 6 }
  method level:sym<trace> ( $/ ) { make 1 }
  method level:sym<debug> ( $/ ) { make 2 }
  method level:sym<info>  ( $/ ) { make 3 }
  method level:sym<warn>  ( $/ ) { make 4 }
  method level:sym<error> ( $/ ) { make 5 }
  method level:sym<fatal> ( $/ ) { make 6 }
  method level:sym<42>    ( $/ ) { make 1 }
  method level:sym<T>     ( $/ ) { make 1 }
  method level:sym<D>     ( $/ ) { make 2 }
  method level:sym<I>     ( $/ ) { make 3 }
  method level:sym<W>     ( $/ ) { make 4 }
  method level:sym<E>     ( $/ ) { make 5 }
  method level:sym<F>     ( $/ ) { make 6 }
  method level:sym<1>     ( $/ ) { make 1 }
  method level:sym<2>     ( $/ ) { make 2 }
  method level:sym<3>     ( $/ ) { make 3 }
  method level:sym<4>     ( $/ ) { make 4 }
  method level:sym<5>     ( $/ ) { make 5 }
  method level:sym<6>     ( $/ ) { make 6 }
  method level:sym<🦋>     ( $/ ) { make 3 }
  method level:sym<✗>     ( $/ ) { make 5 }

}
