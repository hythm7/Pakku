
grammar Pakku::Grammar::Cmd {

  proto rule TOP { * }
  rule TOP:sym<add>    { <add>    <addopt>*    <dist>+   }
  rule TOP:sym<remove> { <remove> <removeopt>* <dist>+   }

  proto token add { * }
  token add:sym<add> { «<sym>» }
  token add:sym<a>   { «<sym>» }
  token add:sym<↓>   { <sym> }

  proto token remove { * }
  token remove:sym<remove> { «<sym>» }
  token remove:sym<r>      { «<sym>» }

  proto rule addopt { * }
  rule addopt:sym<deps> { «<deps>» }
  rule addopt:sym<test> { «<test>» }
  rule addopt:sym<yolo> { «<yolo>» }
  rule addopt:sym<into> { «<into> <path>» }

  proto rule removeopt { * }
  rule removeopt:sym<deps>   { «<deps>» }
  rule removeopt:sym<yolo>   { «<yolo>» }
  rule removeopt:sym<from>   { «<from> <path>» }
 
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

  token dist { «.*» }

  token path { <[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+ }
}

class Pakku::Grammar::Cmd::Actions {

  method TOP:sym<add> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>  = 'add';
    %cmd<add>  = $<addopt>».ast.hash if $<addopt>;
    %cmd<dist> = $<dist>».Str;

    make %cmd;
    
  }

  method TOP:sym<remove> ( $/ ) {

    my %cmd;
    
    %cmd<cmd>  = 'remove';
    %cmd<add>  = $<removeopt>».ast.hash if $<removeopt>;
    %cmd<dist> = $<dist>».Str;

    make %cmd;
    
  }

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

}
