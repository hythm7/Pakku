#no precompilation;
#use Grammar::Tracer;

use Cro::Uri;

grammar Pakku::Grammar::Cmd {

  # TODO: substitute word boundry with suitable token

  proto rule TOP { * }
  rule TOP:sym<add>    { <pakkuopt>* <add>    <addopt>*    <addspecs> }
  rule TOP:sym<remove> { <pakkuopt>* <remove> <removeopt>* <removespecs> }
  rule TOP:sym<search> { <pakkuopt>* <search> <searchopt>* <searchspecs> }


  proto rule pakkuopt { * }
  rule pakkuopt:sym<verbose> { «<verbose>» }
  rule pakkuopt:sym<force>   { «<force>» }
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


  proto rule addopt { * }
  rule addopt:sym<deps> { «<deps>» }
  rule addopt:sym<test> { «<test>» }
  rule addopt:sym<into> { «<into> <path>» }


  proto rule removeopt { * }
  rule removeopt:sym<deps>   { «<deps>» }
  rule removeopt:sym<from>   { «<from> <path>» }

 
  proto rule searchopt { * }
  rule searchopt:sym<deps>   { «<deps>» }


  token addspecs { <addspec>+ %% \s+ }

  proto token addspec { * }
  token addspec:sym<spec> { <spec> }
  token addspec:sym<path> { <path> }
  

  token removespecs { <removespec>+ %% \s+ }

  proto token removespec { * }
  token removespec:sym<spec> { <spec> }
  

  token searchspecs { <searchspec>+ %% \s+ }
  proto token searchsspec { * }
  token searchspec:sym<spec> { <spec> }


  token spec { <name> <keyval>* }


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

  
  token keyval { ':' <key> <value> }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  proto token key { * }
  token key:sym<ver>  { <sym> }
  token key:sym<auth> { <sym> }
  token key:sym<api>  { <sym> }
  token key:sym<from> { <sym> }

  #token value { '<' ~ '>'  [<( [[ <!before \>|\\> . ]+]* % ['\\' . ] )>] }
  token value { '<' ~ '>'  $<val>=[ [[ <!before \>|\\> . ]+]* % ['\\' . ] ] }
  #token value { '<' ~ '>'  \w+ }
  #token value { '<' ~ '>' <-[\s]>+ }

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
    %cmd<add><spec>  = $<addspecs>.ast;

    make %cmd;
    
  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>           = 'remove';
    %cmd<pakku>         = $<pakkuopt>».ast.hash  if $<pakkuopt>;
    %cmd<remove>        = $<removeopt>».ast.hash if $<removeopt>;
    %cmd<remove><spec>  = $<removespecs>.ast;

    make %cmd;
    
  }
  

  method TOP:sym<search> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>           = 'search';
    %cmd<pakku>         = $<pakkuopt>».ast.hash  if $<pakkuopt>;
    %cmd<search>        = $<searchopt>».ast.hash if $<searchopt>;
    %cmd<search><spec>  = $<searchspecs>.ast;

    make %cmd;
    
  }


  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )  }
  method pakkuopt:sym<force>   ( $/ ) { make ( :force )  }
  method pakkuopt:sym<verbose> ( $/ ) { make ( :verbose )  }


  method addopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method addopt:sym<test> ( $/ ) { make $<test>.ast }
  method addopt:sym<into> ( $/ ) { make ( into => $<path>.IO )  }


  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) { make ( from => $<path>.IO )  }


  method searchopt:sym<deps> ( $/ ) { make $<deps>.ast }
  

  method addspecs    ( $/ ) { make $<addspec>».ast    }
  method removespecs ( $/ ) { make $<removespec>».ast }
  method searchspecs ( $/ ) { make $<searchspec>».ast }


  method  addspec:sym<spec> ( $/ ) { make $<spec>.ast }
  method  addspec:sym<path> ( $/ ) { make $<path>.IO  }


  method  removespec:sym<spec> ( $/ ) { make $<spec>.ast }


  method  searchspec:sym<spec> ( $/ ) { make $<spec>.ast }


  method spec ( $/ ) {
    my %id;

    %id<name> = $<name>.Str;
    %id.push: ( $<keyval>».ast ) if $<keyval>;
    
    my %spec;

    %spec<short-name>      = %id<name> if %id<name>;
    %spec<from>            = %id<from> if %id<from>;
    %spec<version-matcher> = %id<ver>  if %id<ver>;
    %spec<auth-matcher>    = %id<auth> if %id<auth>;
    %spec<api-matcher>     = %id<api>  if %id<api>;

    make CompUnit::DependencySpecification.new: |%spec;

  }


  method path ( $/ ) { make $/.IO }


  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }


  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

    
  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }
  method value ( $/ )  { make $<val>.Str }

}
