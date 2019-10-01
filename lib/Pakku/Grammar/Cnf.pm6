#no precompilation;
#use Grammar::Tracer;

grammar Pakku::Grammar::Cnf {

  token TOP { <sections> }

  token sections { <.ws> <section>* }

  proto rule section { * }
  rule section:sym<pakku>  { <lt> <sym> <gt> <.nl> <pakkuopt>+  }
  rule section:sym<add>    { <lt> <sym> <gt> <.nl> <addopt>+    }
  rule section:sym<remove> { <lt> <sym> <gt> <.nl> <removeopt>+ }
  rule section:sym<list>   { <lt> <sym> <gt> <.nl> <listopt>+ }
  rule section:sym<source> { <lt> <sym> <gt> <.nl> <sourceopt>+ }
  rule section:sym<log>    { <lt> <sym> <gt> <.nl> <logopt>+    }

  proto rule pakkuopt { * }
  rule pakkuopt:sym<update>  { <update>             <.eol> }
  rule pakkuopt:sym<pretty>  { <pretty>             <.eol> }
  rule pakkuopt:sym<please>  { <sym>                <.eol> }
  rule pakkuopt:sym<repo>    { <repo>    <reponame> <.eol> }
  rule pakkuopt:sym<verbose> { <verbose> <level>    <.eol> }

  proto rule addopt { * }
  rule addopt:sym<deps>  { <deps>            <.eol> }
  rule addopt:sym<build> { <build>           <.eol> }
  rule addopt:sym<test>  { <test>            <.eol> }
  rule addopt:sym<force> { <force>           <.eol> }
  rule addopt:sym<into>  { <into> <reponame> <.eol> }

  proto rule removeopt { * }
  # rule removeopt:sym<deps> { <deps>            <.eol> }
  rule removeopt:sym<from> { <from> <reponame> <.eol> }

  proto rule listopt { * }
  rule listopt:sym<local>   { <local>              <.eol> }
  rule listopt:sym<remote>  { <remote>             <.eol> }
  rule listopt:sym<details> { <details>            <.eol> }
  rule listopt:sym<repo>    { <repo>    <reponame> <.eol> }

  proto rule sourceopt { * }
  rule sourceopt:sym<source>  { <.ws> <source> <.eol> }

   proto token update { * }
  token update:sym<update>   { <sym> }
  token update:sym<u>        { <sym> }
  token update:sym<noupdate> { <sym> }
  token update:sym<nu>       { <sym> }

  proto token pretty { * }
  token pretty:sym<pretty>   { <sym> }
  token pretty:sym<p>        { <sym> }
  token pretty:sym<nopretty> { <sym> }
  token pretty:sym<np>       { <sym> }

  proto token repo { * }
  token repo:sym<repo> { <sym> }

  proto token verbose { * }
  token verbose:sym<verbose> { <sym> }
  token verbose:sym<v>       { <sym> }


  proto token deps { * }
  token deps:sym<deps>   { <sym> }
  token deps:sym<d>      { <sym> }
  token deps:sym<nodeps> { <sym> }
  token deps:sym<nd>     { <sym> }

  proto token build { * }
  token build:sym<build>   { <sym> }
  token build:sym<b>       { <sym> }
  token build:sym<nobuild> { <sym> }
  token build:sym<nb>      { <sym> }

  proto token test { * }
  token test:sym<test>   { <sym> }
  token test:sym<t>      { <sym> }
  token test:sym<notest> { <sym> }
  token test:sym<nt>     { <sym> }

  proto token force { * }
  token force:sym<force>   { <sym> }
  token force:sym<f>       { <sym> }
  token force:sym<noforce> { <sym> }
  token force:sym<nf>      { <sym> }

  proto token into { * }
  token into:sym<into> { <sym> }

  proto token from { * }
  token from:sym<from> { <sym> }

  proto token remote { * }
  token remote:sym<remote>   { <sym> }
  token remote:sym<r>        { <sym> }
  token remote:sym<noremote> { <sym> }
  token remote:sym<nr>       { <sym> }

  proto token local { * }
  token local:sym<local>   { <sym> }
  token local:sym<l>       { <sym> }
  token local:sym<nolocal> { <sym> }
  token local:sym<nl>      { <sym> }

  proto token details { * }
  token details:sym<details>   { <sym> }
  token details:sym<d>         { <sym> }
  token details:sym<nodetails> { <sym> }
  token details:sym<nd>        { <sym> }

  proto token reponame { * }
  token reponame:sym<home>   { <sym> }
  token reponame:sym<site>   { <sym> }
  token reponame:sym<vendor> { <sym> }
  token reponame:sym<core>   { <sym> }

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

  proto token level { * }
  token level:sym<TRACE> { <sym> }
  token level:sym<DEBUG> { <sym> }
  token level:sym<INFO>  { <sym> }
  token level:sym<WARN>  { <sym> }
  token level:sym<ERROR> { <sym> }
  token level:sym<FATAL> { <sym> }
  token level:sym<trace> { <sym> }
  token level:sym<debug> { <sym> }
  token level:sym<info>  { <sym> }
  token level:sym<warn>  { <sym> }
  token level:sym<error> { <sym> }
  token level:sym<fatal> { <sym> }
  token level:sym<42>    { <sym> }
  token level:sym<T>     { <sym> }
  token level:sym<D>     { <sym> }
  token level:sym<I>     { <sym> }
  token level:sym<W>     { <sym> }
  token level:sym<E>     { <sym> }
  token level:sym<F>     { <sym> }
  token level:sym<1>     { <sym> }
  token level:sym<2>     { <sym> }
  token level:sym<3>     { <sym> }
  token level:sym<4>     { <sym> }
  token level:sym<5>     { <sym> }
  token level:sym<6>     { <sym> }
  token level:sym<🦋>     { <sym> }
  token level:sym<✗>     { <sym> }


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
  method section:sym<list>   ( $/ ) { %!cnf{~$<sym>} = $<listopt>».ast.hash }
  method section:sym<source> ( $/ ) { %!cnf{~$<sym>}.append: $<sourceopt>».ast }

  method logopt:sym<name>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-name>;

  }

  method logopt:sym<color>    ( $/ ) {

    %!cnf<log>{$<level>.ast}{~$<sym>} = ~$<level-color>;

  }
  method pakkuopt:sym<update>  ( $/ ) { make $<update>.ast }
  method pakkuopt:sym<pretty>  ( $/ ) { make $<pretty>.ast }
  method pakkuopt:sym<please>  ( $/ ) { make ( :please )   }
  method pakkuopt:sym<verbose> ( $/ ) { make ( verbose => $<level>.ast ) }

  method pakkuopt:sym<repo>    ( $/ ) {

    my $repo = $<reponame>.ast;

    make ~$<repo> => $repo;

  }


  method addopt:sym<deps>  ( $/ ) { make $<deps>.ast  }
  method addopt:sym<build> ( $/ ) { make $<build>.ast }
  method addopt:sym<test>  ( $/ ) { make $<test>.ast  }
  method addopt:sym<force> ( $/ ) { make $<force>.ast }

  method addopt:sym<into>  ( $/ ) {

    my $into = $<reponame>.ast;

    $into.next-repo = Nil;

    make ~$<into> => $into;

  }


  # method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }

  method removeopt:sym<from> ( $/ ) {

    my $from = $<reponame>.ast;

    $from.next-repo = Nil;

    make ~$<from> => $from;
  }


  method listopt:sym<remote>  ( $/ ) { make $<remote>.ast }
  method listopt:sym<local>   ( $/ ) { make $<local>.ast  }
  method listopt:sym<details> ( $/ ) { make $<details>.ast   }

  method listopt:sym<repo> ( $/ ) {

    my $repo = $<reponame>.ast;

    $repo.next-repo = Nil;

    make ~$<repo> => $repo;
  }


  method sourceopt:sym<source> ( $/ ) { make $<source>.ast }

  method update:sym<update>   ( $/ )  { make ( :update  ) }
  method update:sym<u>        ( $/ )  { make ( :update  ) }
  method update:sym<noupdate> ( $/ )  { make ( :!update ) }
  method update:sym<nu>       ( $/ )  { make ( :!update ) }

  method pretty:sym<pretty>   ( $/ )  { make ( :pretty  ) }
  method pretty:sym<p>        ( $/ )  { make ( :pretty  ) }
  method pretty:sym<nopretty> ( $/ )  { make ( :!pretty ) }
  method pretty:sym<np>       ( $/ )  { make ( :!pretty ) }

  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }

  method build:sym<build>   ( $/ )  { make ( :build  ) }
  method build:sym<b>       ( $/ )  { make ( :build  ) }
  method build:sym<nobuild> ( $/ )  { make ( :!build ) }
  method build:sym<nb>      ( $/ )  { make ( :!build ) }

  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

  method force:sym<force>   ( $/ )  { make ( :force  ) }
  method force:sym<f>       ( $/ )  { make ( :force  ) }
  method force:sym<noforce> ( $/ )  { make ( :!force ) }
  method force:sym<nf>      ( $/ )  { make ( :!force ) }

  method remote:sym<remote>   ( $/ )  { make ( :remote  ) }
  method remote:sym<r>        ( $/ )  { make ( :remote  ) }
  method remote:sym<noremote> ( $/ )  { make ( :!remote ) }
  method remote:sym<nr>       ( $/ )  { make ( :!remote ) }

  method local:sym<local>   ( $/ ) { make ( :local  ) }
  method local:sym<l>       ( $/ ) { make ( :local  ) }
  method local:sym<nolocal> ( $/ ) { make ( :!local ) }
  method local:sym<nl>      ( $/ ) { make ( :!local ) }

  method details:sym<details>   ( $/ ) { make ( :details  ) }
  method details:sym<d>         ( $/ ) { make ( :details  ) }
  method details:sym<nodetails> ( $/ ) { make ( :!details ) }
  method details:sym<nd>        ( $/ ) { make ( :!details ) }

  method reponame:sym<home> ( $/ ) {
    make CompUnit::RepositoryRegistry.repository-for-name: $<sym>.Str
  }

  method reponame:sym<site> ( $/ ) {
    make CompUnit::RepositoryRegistry.repository-for-name: $<sym>.Str
  }

  method reponame:sym<vendor> ( $/ ) {
    make CompUnit::RepositoryRegistry.repository-for-name: $<sym>.Str
  }

  method reponame:sym<core> ( $/ ) {
    make CompUnit::RepositoryRegistry.repository-for-name: $<sym>.Str
  }

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
