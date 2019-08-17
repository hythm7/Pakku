#no precompilation;
#use Grammar::Tracer;

grammar Pakku::Grammar::Cmd {

  proto rule TOP { * }
  rule TOP:sym<add>    { <add>    <addopt>*    <idents> }
  rule TOP:sym<remove> { <remove> <removeopt>* <idents> }
  rule TOP:sym<search> { <search> <searchopt>* <idents> }

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
  rule addopt:sym<yolo> { «<yolo>» }
  rule addopt:sym<into> { «<into> <path>» }

  proto rule removeopt { * }
  rule removeopt:sym<deps>   { «<deps>» }
  rule removeopt:sym<yolo>   { «<yolo>» }
  rule removeopt:sym<from>   { «<from> <path>» }
 
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

  proto token yolo { * }
  token yolo:sym<yolo> { «<sym>» }
  token yolo:sym<y>    { «<sym>» }
  token yolo:sym<✓>    { «<sym>» }

  token idents { <ident>+ %% \s+ }
  token ident { <name> <keyval>* }
  token keyval { ':' <key> <value> }

  #token name { <-[:<>]>+ %% '::' }
  token name { [<-[:<>()]>+]+ % '::' }

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
    %cmd<add>        = $<addopt>».ast.hash if $<addopt>;
    %cmd<add><ident> = $<idents>.ast;

    make %cmd;
    
  }

  method TOP:sym<remove> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>           = 'remove';
    %cmd<remove>        = $<removeopt>».ast.hash if $<removeopt>;
    %cmd<remove><ident> = $<idents>.ast;

    make %cmd;
    
  }
  
  method TOP:sym<search> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>           = 'search';
    %cmd<search>        = $<searchopt>».ast.hash if $<searchopt>;
    %cmd<search><ident> = $<idents>.ast;

    make %cmd;
    
  }


  method addopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method addopt:sym<test> ( $/ ) { make $<test>.ast }
  method addopt:sym<into> ( $/ ) { make ( into => $<path>.IO )  }
  method addopt:sym<yolo> ( $/ ) { make ( :yolo )  }

  method removeopt:sym<deps> ( $/ ) { make $<deps>.ast }
  method removeopt:sym<from> ( $/ ) { make ( from => $<path>.IO )  }
  method removeopt:sym<yolo> ( $/ ) { make ( :yolo )  }

  method searchopt:sym<deps> ( $/ ) { make $<deps>.ast }
  
  method deps:sym<deps>   ( $/ )  { make ( :deps  ) }
  method deps:sym<d>      ( $/ )  { make ( :deps  ) }
  method deps:sym<nodeps> ( $/ )  { make ( :!deps ) }
  method deps:sym<nd>     ( $/ )  { make ( :!deps ) }

  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

  method idents ( $/ ) { make $<ident>».ast }

  method ident ( $/ ) {
    my %ident;

    %ident<name> = $<name>.Str;
    %ident.push: ( $<keyval>».ast ) if $<keyval>;

    make %ident;

  }

  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }
  method value ( $/ ) { make $<val>.Str }

}
