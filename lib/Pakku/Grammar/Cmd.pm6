
use Pakku::Grammar::Common;

grammar Pakku::Grammar::Cmd {
  also does Pakku::Grammar::Common;


  proto rule TOP { * }
  rule TOP:sym<add>    { <pakkuopt>* % <.space> <add>    <addopt>*    % <.space> <whats>    }
  rule TOP:sym<build>  { <pakkuopt>* % <.space> <build>  <buildopt>*  % <.space> <whats>    }
  rule TOP:sym<test>   { <pakkuopt>* % <.space> <test>   <testopt>*   % <.space> <whats>    }
  rule TOP:sym<remove> { <pakkuopt>* % <.space> <remove> <removeopt>* % <.space> <whats>    }
  rule TOP:sym<check>  { <pakkuopt>* % <.space> <check>  <checkopt>*  % <.space> <whats>    }
  rule TOP:sym<list>   { <pakkuopt>* % <.space> <list>   <listopt>*   % <.space> <whats>?   }
  rule TOP:sym<help>   { <help>? <cmd>? <anything> }


  proto token cmd { * }
  token cmd:sym<add>    { <!before <.space>> ~ <!after <.space>> <add>    }
  token cmd:sym<build>  { <!before <.space>> ~ <!after <.space>> <build>  }
  token cmd:sym<test>   { <!before <.space>> ~ <!after <.space>> <test>   }
  token cmd:sym<remove> { <!before <.space>> ~ <!after <.space>> <remove> }
  token cmd:sym<check>  { <!before <.space>> ~ <!after <.space>> <check>  }
  token cmd:sym<list>   { <!before <.space>> ~ <!after <.space>> <list>   }
  token cmd:sym<help>   { <!before <.space>> ~ <!after <.space>> <help>   }

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


  method TOP:sym<build> ( $/ ) {

    my %cmd;

    %cmd<cmd>         = 'build';
    %cmd<pakku>       = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<build>       = $<buildopt>».ast.hash if defined $<buildopt>;
    %cmd<build><what> = $<whats>.ast;

    make %cmd;

  }

  method TOP:sym<test> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'test';
    %cmd<pakku>      = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<test>       = $<testopt>».ast.hash  if defined $<testopt>;
    %cmd<test><what> = $<whats>.ast;

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

  method TOP:sym<check> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'check';
    %cmd<pakku>        = $<pakkuopt>».ast.hash if defined $<pakkuopt>;
    %cmd<check>       = $<checkopt>».ast.hash  if defined $<checkopt>;
    %cmd<check><what> = $<whats>.ast;

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
  method cmd:sym<build>  ( $/ ) { make 'build'  }
  method cmd:sym<test>   ( $/ ) { make 'test'   }
  method cmd:sym<remove> ( $/ ) { make 'remove' }
  method cmd:sym<check>  ( $/ ) { make 'check'  }
  method cmd:sym<list>   ( $/ ) { make 'list'   }
  method cmd:sym<help>   ( $/ ) { make 'help'   }

}
