use Pakku::Grammar::Common;

class X::Pakku::Cmd {
  also is Exception;

  has $.cmd;

  method message ( --> Str:D ) {

    "CMD: ｢$!cmd｣";

  }

}

grammar Pakku::Grammar::Cmd {
  also does Pakku::Grammar::Common;


  proto rule TOP { * }
  rule TOP:sym<add>      { <pakkuopt>* % <.space> <add>       <addopt>*      % <.space> <whats>    }
  rule TOP:sym<upgrade>  { <pakkuopt>* % <.space> <upgrade>   <upgradeopt>*  % <.space> <whats>    }
  rule TOP:sym<build>    { <pakkuopt>* % <.space> <build>     <buildopt>*    % <.space> <what>     }
  rule TOP:sym<test>     { <pakkuopt>* % <.space> <test>      <testopt>*     % <.space> <what>     }
  rule TOP:sym<remove>   { <pakkuopt>* % <.space> <remove>    <removeopt>*   % <.space> <whats>    }
  rule TOP:sym<checkout> { <pakkuopt>* % <.space> <checkout>  <checkoutopt>* % <.space> <whats>    }
  rule TOP:sym<search>   { <pakkuopt>* % <.space> <search>    <searchopt>*   % <.space> <whats>    }
  rule TOP:sym<list>     { <pakkuopt>* % <.space> <list>      <listopt>*     % <.space> <whats>?   }
  rule TOP:sym<help>     { <pakkuopt>* % <.space> <help>?     <cmd>?                    <anything> }


  proto token cmd { * }
  token cmd:sym<add>      { <!before <.space>> ~ <!after <.space>> <add>      }
  token cmd:sym<upgrade>  { <!before <.space>> ~ <!after <.space>> <upgrade>  }
  token cmd:sym<build>    { <!before <.space>> ~ <!after <.space>> <build>    }
  token cmd:sym<test>     { <!before <.space>> ~ <!after <.space>> <test>     }
  token cmd:sym<remove>   { <!before <.space>> ~ <!after <.space>> <remove>   }
  token cmd:sym<checkout> { <!before <.space>> ~ <!after <.space>> <checkout> }
  token cmd:sym<search>   { <!before <.space>> ~ <!after <.space>> <search>   }
  token cmd:sym<list>     { <!before <.space>> ~ <!after <.space>> <list>     }
  token cmd:sym<help>     { <!before <.space>> ~ <!after <.space>> <help>     }

}

class Pakku::Grammar::CmdActions {
  also does Pakku::Grammar::CommonActions;


  method TOP:sym<add> ( $/ ) {

    my %cmd;

    %cmd<cmd>       = 'add';
    %cmd<pakku>     = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<add>       = $<addopt>».made.hash   if defined $<addopt>;
    %cmd<add><spec> = $<whats>.made;

    make %cmd;

  }


  method TOP:sym<upgrade> ( $/ ) {

    my %cmd;

    %cmd<cmd>           = 'upgrade';
    %cmd<pakku>         = $<pakkuopt>».made.hash   if defined $<pakkuopt>;
    %cmd<upgrade>       = $<upgradeopt>».made.hash if defined $<upgradeopt>;
    %cmd<upgrade><spec> = $<whats>.made;

    make %cmd;

  }

  method TOP:sym<build> ( $/ ) {

    my %cmd;

    %cmd<cmd>         = 'build';
    %cmd<pakku>       = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<build>       = $<buildopt>».made.hash if defined $<buildopt>;
    %cmd<build><spec> = $<what>.made;

    make %cmd;

  }

  method TOP:sym<test> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'test';
    %cmd<pakku>      = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<test>       = $<testopt>».made.hash  if defined $<testopt>;
    %cmd<test><spec> = $<what>.made;

    make %cmd;

  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'remove';
    %cmd<pakku>        = $<pakkuopt>».made.hash  if defined $<pakkuopt>;
    %cmd<remove>       = $<removeopt>».made.hash if defined $<removeopt>;
    %cmd<remove><spec> = $<whats>.made;

    make %cmd;

  }

  method TOP:sym<checkout> ( $/ ) {

    my %cmd;

    %cmd<cmd>            = 'checkout';
    %cmd<pakku>          = $<pakkuopt>».made.hash     if defined $<pakkuopt>;
    %cmd<checkout>       = $<checkoutopt>».made.hash  if defined $<checkoutopt>;
    %cmd<checkout><spec> = $<whats>.made;

    make %cmd;

  }


  method TOP:sym<list> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'list';
    %cmd<pakku>      = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<list>       = $<listopt>».made.hash  if defined $<listopt>;
    %cmd<list><spec> = $<whats>.made          if defined $<whats>;

    make %cmd;

  }


  method TOP:sym<search> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'search';
    %cmd<pakku>        = $<pakkuopt>».made.hash   if defined $<pakkuopt>;
    %cmd<search>       = $<searchopt>».made.hash  if defined $<searchopt>;
    %cmd<search><spec> = $<whats>.made;

    make %cmd;

  }


  method TOP:sym<help> ( $/ ) {

    my %cmd;

    %cmd<cmd>       = 'help';
    %cmd<pakku>     = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<help><cmd> = $<cmd>.so ?? $<cmd>.made !! '';

    make %cmd;

  }

  method cmd:sym<add>      ( $/ ) { make 'add'      }
  method cmd:sym<upgrade>  ( $/ ) { make 'upgrade'      }
  method cmd:sym<build>    ( $/ ) { make 'build'    }
  method cmd:sym<test>     ( $/ ) { make 'test'     }
  method cmd:sym<remove>   ( $/ ) { make 'remove'   }
  method cmd:sym<checkout> ( $/ ) { make 'checkout' }
  method cmd:sym<list>     ( $/ ) { make 'list'     }
  method cmd:sym<search>   ( $/ ) { make 'search'     }
  method cmd:sym<help>     ( $/ ) { make 'help'     }

}
