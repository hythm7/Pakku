#no precompilation;
#use Grammar::Tracer;

use Cro::Uri;

use Pakku::Specification;

grammar Pakku::Grammar::Cmd {

  # TODO: substitute word boundry with suitable token

  proto rule TOP { * }
  rule TOP:sym<add>    { <pakkuopt>* <add>    <addopt>*    <specs> }
  rule TOP:sym<remove> { <pakkuopt>* <remove> <removeopt>* <specs> }
  rule TOP:sym<list>   { <pakkuopt>* <list>   <listopt>*   <specs>? }


  proto rule pakkuopt { * }
  rule pakkuopt:sym<repo>    { «<repo> <reponame>» }
  rule pakkuopt:sym<verbose> { «<verbose> <level>» }
  rule pakkuopt:sym<pretty>  { «<pretty>» }
  rule pakkuopt:sym<please>  { «<sym>» }
  rule pakkuopt:sym<yolo>    { «<yolo>» }


  proto token add { * }
  token add:sym<add> { «<sym>» }
  token add:sym<a>   { «<sym>» }
  token add:sym<↓>   {  <sym>  }


  proto token remove { * }
  token remove:sym<remove> { «<sym>» }
  token remove:sym<r>      { «<sym>» }


  proto token list { * }
  token list:sym<list> { «<sym>» }
  token list:sym<l>    { «<sym>» }

  proto token repo { * }
  token repo:sym<repo> { «<sym>» }

  proto token reponame { * }
  token reponame:sym<home>   { «<sym>» }
  token reponame:sym<site>   { «<sym>» }
  token reponame:sym<vendor> { «<sym>» }


  proto rule addopt { * }
  rule addopt:sym<deps>  { «<deps>» }
  rule addopt:sym<build> { «<build>» }
  rule addopt:sym<test>  { «<test>» }
  rule addopt:sym<force> { «<force>» }
  rule addopt:sym<into>  { «<into> <reponame>» }


  proto rule removeopt { * }
  rule removeopt:sym<deps> { «<deps>» }
  rule remove:sym<force>   { «<force>» }
  rule removeopt:sym<from> { «<from> <reponame>» }


  proto rule listopt { * }
  rule listopt:sym<remote> { «<remote>» }
  rule listopt:sym<info>   { «<info>» }

  proto token deps { * }
  token deps:sym<deps>   { «<sym>» }
  token deps:sym<d>      { «<sym>» }
  token deps:sym<nodeps> { «<sym>» }
  token deps:sym<nd>     { «<sym>» }

  proto token build { * }
  token build:sym<build>   { «<sym>» }
  token build:sym<b>       { «<sym>» }
  token build:sym<nobuild> { «<sym>» }
  token build:sym<nb>      { «<sym>» }

  proto token test { * }
  token test:sym<test>   { «<sym>» }
  token test:sym<t>      { «<sym>» }
  token test:sym<notest> { «<sym>» }
  token test:sym<nt>     { «<sym>» }

  proto token into { * }
  token into:sym<into> { «<sym>» }

  proto token from { * }
  token from:sym<from> { «<sym>» }

  proto token remote { * }
  token remote:sym<remote>   { «<sym>» }
  token remote:sym<r>        { «<sym>» }
  token remote:sym<noremote> { «<sym>» }
  token remote:sym<nr>       { «<sym>» }

  proto token info { * }
  token info:sym<info>   { «<sym>» }
  token info:sym<i>      { «<sym>» }
  token info:sym<noinfo> { «<sym>» }
  token info:sym<ni>     { «<sym>» }

  proto token pretty { * }
  token pretty:sym<pretty>   { «<sym>» }
  token pretty:sym<p>        { «<sym>» }
  token pretty:sym<nopretty> { «<sym>» }
  token pretty:sym<np>       { «<sym>» }

  proto token verbose { * }
  token verbose:sym<verbose> { «<sym>» }
  token verbose:sym<v>       { «<sym>» }

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
  token level:sym<✓>     { «<sym>» }
  token level:sym<✗>     { «<sym>» }

  proto token force { * }
  token force:sym<force> { «<sym>» }
  token force:sym<f>    { «<sym>» }

  proto token yolo { * }
  token yolo:sym<yolo> { «<sym>» }
  token yolo:sym<y>    { «<sym>» }
  token yolo:sym<✓>    { «<sym>» }


  token specs { <spec>+ % \h }

  proto token spec { * }
  token spec:sym<spec> { <name> <keyval>* }
  token spec:sym<path> { <path> }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token keyval { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<version> { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<api>     { <sym> }
  token key:sym<from>    { <sym> }

  token value { '<' $<val>=<-[<>]>+ '>' | '(' $<val>=<-[()]>+ ')' }

  token path { <[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+ }

  token lt { '<' }
  token gt { '>' }
}

class Pakku::Grammar::Cmd::Actions {


  method TOP:sym<add> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'add';
    %cmd<pakku>      = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<add>        = $<addopt>».ast.hash   if defined $<addopt>;
    %cmd<add><spec>  = $<specs>.ast;

    make %cmd;

  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;

    %cmd<cmd>           = 'remove';
    %cmd<pakku>         = $<pakkuopt>».ast.hash  if defined $<pakkuopt>;
    %cmd<remove>        = $<removeopt>».ast.hash if defined $<removeopt>;
    %cmd<remove><spec>  = $<specs>.ast;

    make %cmd;

  }


  method TOP:sym<list> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'list';
    %cmd<pakku>      = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<list>       = $<listopt>».ast.hash    if defined $<listopt>;
    %cmd<list><spec> = $<specs>.ast            if defined $<specs>;

    make %cmd;

  }


  method pakkuopt:sym<repo>    ( $/ ) {
    my $repo = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<repo> => $repo;
  }
  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )  }
  method pakkuopt:sym<pretty>  ( $/ ) { make ( $<pretty>.ast )  }
  method pakkuopt:sym<please>  ( $/ ) { make ( :please )  }
  method pakkuopt:sym<verbose> ( $/ ) { make ( verbose => $<level>.ast ) }


  method addopt:sym<deps>  ( $/ ) { make $<deps>.ast }
  method addopt:sym<build> ( $/ ) { make $<build>.ast }
  method addopt:sym<test>  ( $/ ) { make $<test>.ast }
  method addopt:sym<force> ( $/ ) { make ( :force )  }

  method addopt:sym<into>  ( $/ ) {
    my $into = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>;
    make ( $<into> => $into );
  }


  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) {
    my $from = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>;
    make ( $<from> => $from );
  }


  method listopt:sym<remote> ( $/ ) { make $<remote>.ast }
  method listopt:sym<info>   ( $/ ) { make $<info>.ast }


  method specs ( $/ ) { make $<spec>».ast    }

  method spec:sym<spec> ( $/ ) {

    make Pakku::Specification.new: spec => $/.Str;

  }

  method spec:sym<path> ( $/ ) { make $/.IO }

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

  method remote:sym<remote>   ( $/ )  { make ( :remote  ) }
  method remote:sym<r>        ( $/ )  { make ( :remote  ) }
  method remote:sym<noremote> ( $/ )  { make ( :!remote ) }
  method remote:sym<nr>       ( $/ )  { make ( :!remote ) }

  method info:sym<info>   ( $/ )  { make ( :info  ) }
  method info:sym<i>      ( $/ )  { make ( :info  ) }
  method info:sym<noinfo> ( $/ )  { make ( :!info ) }
  method info:sym<ni>     ( $/ )  { make ( :!info ) }

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
  method level:sym<✓>     ( $/ ) { make 3 }
  method level:sym<✗>     ( $/ ) { make 5 }

}
