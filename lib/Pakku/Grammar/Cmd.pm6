
use Pakku::Grammar::Common;

use Cro::Uri;

use Pakku::DepSpec;

grammar Pakku::Grammar::Cmd {
  also does Pakku::Grammar::Common;


  proto rule TOP { * }
  rule TOP:sym<add>    { <pakkuopt>* % <.space> <add>    <addopt>*    % <.space> <whats>    }
  rule TOP:sym<remove> { <pakkuopt>* % <.space> <remove> <removeopt>* % <.space> <whats>    }
  rule TOP:sym<list>   { <pakkuopt>* % <.space> <list>   <listopt>*   % <.space> <whats>?   }
  rule TOP:sym<help>   { <help>? <cmd>? <anything> }


  proto token cmd { * }
  token cmd:sym<add>    { <!before <.space>> ~ <!after <.space>> <add> }
  token cmd:sym<remove> { <!before <.space>> ~ <!after <.space>> <remove> }
  token cmd:sym<list>   { <!before <.space>> ~ <!after <.space>> <list> }
  token cmd:sym<help>   { <!before <.space>> ~ <!after <.space>> <help> }


  proto token add { * }
  token add:sym<add> { <sym> }
  token add:sym<a>   { <sym> }
  token add:sym<↓>   { <sym>  }

  proto token remove { * }
  token remove:sym<remove> { <sym> }
  token remove:sym<r>      { <sym> }
  token remove:sym<↑>      { <sym> }

  proto token list { * }
  token list:sym<list> { <sym> }
  token list:sym<l>    { <sym> }
  token list:sym<↪>    { <sym> }

  proto token help { * }
  token help:sym<help> { <sym> }
  token help:sym<h>    { <sym> }
  token help:sym<ℍ>    { <sym> }
  token help:sym<?>    { <sym> }
  token help:sym<❓>    { <sym> }


  token whats { <what>+ % \h }

  proto token what { * }
  token what:sym<spec> { <spec> }
  token what:sym<path> { <path> }

  token spec { <name> <keyval>* }
  token path { <[ a..z A..Z 0..9 \-_.!~*'():@&=+$,/ ]>+ }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token keyval { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<api>     { <sym> }
  token key:sym<from>    { <sym> }
  token key:sym<version> { <sym> }

  proto token value { * }
  token value:sym<angles> { '<' ~ '>' $<val>=[.*? <~~>?] }
  token value:sym<parens> { '(' ~ ')' $<val>=[.*? <~~>?] }


  token anything { .* }
}

class Pakku::Grammar::Cmd::Actions {
  also does Pakku::Grammar::Common::Actions;


  method TOP:sym<add> ( $/ ) {

    my %cmd;

    %cmd<cmd>       = 'add';
    %cmd<pakku>     = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<add>       = $<addopt>».ast.hash   if defined $<addopt>;
    %cmd<add><what> = $<whats>.ast;

    make %cmd;

  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'remove';
    %cmd<pakku>        = $<pakkuopt>».ast.hash  if defined $<pakkuopt>;
    %cmd<remove>       = $<removeopt>».ast.hash if defined $<removeopt>;
    %cmd<remove><what> = $<whats>.ast;

    make %cmd;

  }


  method TOP:sym<list> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'list';
    %cmd<pakku>      = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<list>       = $<listopt>».ast.hash  if defined $<listopt>;
    %cmd<list><what> = $<whats>.ast          if defined $<whats>;

    make %cmd;

  }


  method TOP:sym<help> ( $/ ) {

    my %cmd;

    %cmd<cmd>  = 'help';
    %cmd<help><cmd> = $<cmd>.so ?? $<cmd>.ast !! '';

    make %cmd;

  }

  method cmd:sym<add>    ( $/ ) { make 'add'    }
  method cmd:sym<list>   ( $/ ) { make 'list'   }
  method cmd:sym<help>   ( $/ ) { make 'help'   }
  method cmd:sym<remove> ( $/ ) { make 'remove' }

  method whats ( $/ ) { make $<what>».ast }

  method what:sym<spec> ( $/ ) { make $<spec>.ast }
  method what:sym<path> ( $/ ) { make $<path>.ast }

  method spec ( $/ ) {

    make Pakku::DepSpec.new: $/.Str;

  }
}
