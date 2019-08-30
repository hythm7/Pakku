#no precompilation;
#use Grammar::Tracer;

use Cro::Uri;

use Pakku::Specification;

grammar Pakku::Grammar::Cmd {

  # TODO: substitute word boundry with suitable token

  proto rule TOP { * }
  rule TOP:sym<add>    { <pakkuopt>* <add>    <addopt>*    <specs> }
  rule TOP:sym<remove> { <pakkuopt>* <remove> <removeopt>* <specs> }
  rule TOP:sym<search> { <pakkuopt>* <search> <searchopt>* <specs> }


  proto rule pakkuopt { * }
  rule pakkuopt:sym<repo>    { «<repo> <reponame>» }
  rule pakkuopt:sym<verbose> { «<verbose>» }
  rule pakkuopt:sym<yolo>    { «<yolo>» }


  proto token add { * }
  token add:sym<add> { «<sym>» }
  token add:sym<a>   { «<sym>» }
  token add:sym<↓>   { <sym> }


  proto token remove { * }
  token remove:sym<remove> { «<sym>» }
  token remove:sym<r>      { «<sym>» }


  proto token search { * }
  token search:sym<search> { «<sym>» }
  token search:sym<s>      { «<sym>» }

  proto token repo { * }
  token repo:sym<repo> { «<sym>» }

  proto token reponame { * }
  token reponame:sym<home>   { «<sym>» }
  token reponame:sym<site>   { «<sym>» }
  token reponame:sym<vendor> { «<sym>» }


  proto rule addopt { * }
  rule addopt:sym<deps>  { «<deps>» }
  rule addopt:sym<test>  { «<test>» }
  rule addopt:sym<force> { «<force>» }
  rule addopt:sym<into>  { «<into> <reponame>» }


  proto rule removeopt { * }
  rule removeopt:sym<deps> { «<deps>» }
  rule remove:sym<force>   { «<force>» }
  rule removeopt:sym<from> { «<from> <reponame>» }


  proto rule searchopt { * }
  rule searchopt:sym<deps>   { «<deps>» }


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

  proto token into { * }
  token into:sym<into> { «<sym>» }

  proto token from { * }
  token from:sym<from> { «<sym>» }

  proto token verbose { * }
  token verbose:sym<verbose> { «<sym>» }
  token verbose:sym<v>    { «<sym>» }

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
    %cmd<pakku>      = $<pakkuopt>».ast.hash if $<pakkuopt>;
    %cmd<add>        = $<addopt>».ast.hash   if $<addopt>;
    %cmd<add><spec>  = $<specs>.ast;

    make %cmd;

  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;

    %cmd<cmd>           = 'remove';
    %cmd<pakku>         = $<pakkuopt>».ast.hash  if $<pakkuopt>;
    %cmd<remove>        = $<removeopt>».ast.hash if $<removeopt>;
    %cmd<remove><spec>  = $<specs>.ast;

    make %cmd;

  }


  method TOP:sym<search> ( $/ ) {

    my %cmd;

    %cmd<cmd>           = 'search';
    %cmd<pakku>         = $<pakkuopt>».ast.hash  if $<pakkuopt>;
    %cmd<search>        = $<searchopt>».ast.hash if $<searchopt>;
    %cmd<search><spec>  = $<specs>.ast;

    make %cmd;

  }


  method pakkuopt:sym<repo>    ( $/ ) {
    my $repo = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<repo> => $repo;
  }
  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )  }
  method pakkuopt:sym<verbose> ( $/ ) { make ( :verbose )  }


  method addopt:sym<deps>  ( $/ ) { make $<deps>.ast }
  method addopt:sym<test>  ( $/ ) { make $<test>.ast }
  method addopt:sym<force> ( $/ ) { make ( :force )  }
  method addopt:sym<into>  ( $/ ) {
    my $into = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<into> => $into;
  }


  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) {
    my $from = CompUnit::RepositoryRegistry.repository-for-name: ~$<reponame>, next-repo => $*REPO;
    make $<from> => $from;
  }


  method searchopt:sym<deps> ( $/ ) { make $<deps>.ast }


  method specs ( $/ ) { make $<spec>».ast    }

  method spec:sym<spec> ( $/ ) {

    make Pakku::Specification.new: spec => $/.Str;

  }

  method spec:sym<path> ( $/ ) { make $/.IO }


  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }


  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

}
