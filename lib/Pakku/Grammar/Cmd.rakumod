grammar Pakku::Grammar::Cmd {

  proto rule TOP { * }
  rule TOP:sym<add>      { :my @*exclude; <pakkuopt>* % <.space> <add>       <addopt>*      % <.space> [ <specs> || <path> ]    }
  rule TOP:sym<upgrade>  { :my @*exclude; <pakkuopt>* % <.space> <upgrade>   <upgradeopt>*  % <.space> <specs>    }

  rule TOP:sym<build>    { <pakkuopt>* % <.space> <build>     <buildopt>*    % <.space> [ <spec> || <path> ]     }
  rule TOP:sym<test>     { <pakkuopt>* % <.space> <test>      <testopt>*     % <.space> [ <spec> || <path> ]     }
  rule TOP:sym<remove>   { <pakkuopt>* % <.space> <remove>    <removeopt>*   % <.space> <specs>    }
  rule TOP:sym<download> { <pakkuopt>* % <.space> <download>  <downloadopt>* % <.space> <specs>    }
  rule TOP:sym<search>   { <pakkuopt>* % <.space> <search>    <searchopt>*   % <.space> <specs>    }
  rule TOP:sym<list>     { <pakkuopt>* % <.space> <list>      <listopt>*     % <.space> <specs>?   }

  rule TOP:sym<config>   { <pakkuopt>* % <.space> <config-cmd>                                     }

  rule TOP:sym<help>     { <pakkuopt>* % <.space> <help>?     <cmd>?                    <anything> }


  proto token config-cmd { * } 
  token config-cmd:sym<config-module-enable>           { <config> <.space> <config-module> <.space>+ <enable> <.space>+ <key-option>+ % <.space> }
  token config-cmd:sym<config-module-disable>          { <config> <.space> <config-module> <.space>+ <disable> <.space>+ <key-option>+ % <.space> }
  token config-cmd:sym<config-module-set>              { <config> <.space> <config-module> <.space>+ <set> <.space>+ <keyval-option>+ % <.space> }
  token config-cmd:sym<config-module-unset-option>     { <config> <.space> <config-module> <.space>+ <unset> <.space>+ <key-option>+ % <.space> }
  token config-cmd:sym<config-module-recman-set>       { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> <.space>+ <set> <.space>+ <keyval-option>+ % <.space> }
  token config-cmd:sym<config-module-recman-enable>    { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> <.space>+ <enable> }
  token config-cmd:sym<config-module-recman-disable>   { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> <.space>+ <disable> }
  token config-cmd:sym<config-module-recman-unset>     { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> <.space>+ <unset> }
  token config-cmd:sym<config-module-log-set>          { <config> <.space>+ <config-module-log> <.space>+ <log-level> <.space>+ <set> <.space>+ <log-level-option>+ % <.space> }
  token config-cmd:sym<config-module-log-unset>        { <config> <.space>+ <config-module-log> <.space>+ <log-level> <.space>+ <unset> }
  token config-cmd:sym<config-module-reset>            { <config> <.space>+ <config-module-any> <.space>+ <reset> }
  token config-cmd:sym<config-module-unset>            { <config> <.space>+ <config-module-any> <.space>+ <unset> }

  token config-cmd:sym<config-recman-name-view-option> { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> [ <.space>+ <view> ]? <.space>+  <key-option>+ % <.space> }
  token config-cmd:sym<config-log-level-view-option>   { <config> <.space>+ <config-module-log> <.space>+ <log-level> [ <.space>+ <view> ]? <.space>+  <key-option>+ % <.space> }
  token config-cmd:sym<config-recman-name-view>        { <config> <.space>+ <config-module-recman> <.space>+ <recman-name> [ <.space>+ <view> ]? }
  token config-cmd:sym<config-log-level-view>          { <config> <.space>+ <config-module-log> <.space>+ <log-level> [ <.space>+ <view> ]? }
  token config-cmd:sym<config-module-view-option>      { <config> <.space>+ <config-module> [ <.space>+ <view> ]? <.space>+  <key-option>+ % <.space> }
  token config-cmd:sym<config-module-view>             { <config> <.space>+ <config-module-any> [ <.space>+ <view> ]? }
  token config-cmd:sym<config-reset>                   { <config> <.space>+ <reset> }
  token config-cmd:sym<config-new>                     { <config> <.space>+ <config-new> }
  token config-cmd:sym<config-view>                    { <config> [ <.space>+  <view> ]? }

  proto token config-module { * } 
  token config-module:sym<pakku>    { <sym> }
  token config-module:sym<add>      { <sym> }
  token config-module:sym<upgrade>  { <sym> }
  token config-module:sym<build>    { <sym> }
  token config-module:sym<test>     { <sym> }
  token config-module:sym<remove>   { <sym> }
  token config-module:sym<list>     { <sym> }
  token config-module:sym<search>   { <sym> }
  token config-module:sym<download> { <sym> }

  token config-module-recman { <module-recman> }
  token config-module-log    { <module-log>    }

  proto token config-module-any { * } 
  token config-module-any:sym<module> { <config-module> }
  token config-module-any:sym<recman> { <config-module-recman> }
  token config-module-any:sym<log>    { <config-module-log> }


  token module-recman   { 'recman'   }
  token module-log      { 'log'      }

  token enable     { 'enable'  }
  token disable    { 'disable' }
  token set        { 'set'     }
  token unset      { 'unset'   }
  token reset      { 'reset'   }
  token view       { 'view'   }
  token config-new { 'new'     } # looks like token new is reserved

  token recman-name   { <key> }

  proto token log-level { * } 
  token log-level:sym<debug> { <sym> }
  token log-level:sym<now>   { <sym> }
  token log-level:sym<info>  { <sym> }
  token log-level:sym<warn>  { <sym> }
  token log-level:sym<error> { <sym> }

  proto token log-level-option { * } 
  token log-level-option:sym<prefix> { <sym> <.space>+ <value> }
  token log-level-option:sym<color>  { <sym> <.space>+ <value> }

  token key-option    { <key> }
  token keyval-option { <key> <.space>+ <value> }

  proto token cmd { * } 
  token cmd:sym<add>      { <!before <.space>> ~ <!after <.space>> <add>      }
  token cmd:sym<upgrade>  { <!before <.space>> ~ <!after <.space>> <upgrade>  }
  token cmd:sym<build>    { <!before <.space>> ~ <!after <.space>> <build>    }
  token cmd:sym<test>     { <!before <.space>> ~ <!after <.space>> <test>     }
  token cmd:sym<remove>   { <!before <.space>> ~ <!after <.space>> <remove>   }
  token cmd:sym<download> { <!before <.space>> ~ <!after <.space>> <download> }
  token cmd:sym<search>   { <!before <.space>> ~ <!after <.space>> <search>   }
  token cmd:sym<list>     { <!before <.space>> ~ <!after <.space>> <list>     }
  token cmd:sym<config>   { <!before <.space>> ~ <!after <.space>> <config>   }
  token cmd:sym<help>     { <!before <.space>> ~ <!after <.space>> <help>     }

  token key   { <-[\s]>+ }
  token value { <-[\s]>+ }

  proto token add { * }
  token add:sym<add> { <sym> }
  token add:sym<a>   { <sym> }
  token add:sym<↓>   { <sym>  }

  proto token upgrade { * }
  token upgrade:sym<upgrade> { <sym> }
  token upgrade:sym<up>      { <sym> }
  token upgrade:sym<u>       { <sym> }
  token upgrade:sym<↑>       { <sym> }

  proto token remove { * }
  token remove:sym<remove> { <sym> }
  token remove:sym<r>      { <sym> }

  proto token download { * }
  token download:sym<download> { <sym> }
  token download:sym<down>     { <sym> }
  token download:sym<d>        { <sym> }


  proto token list { * }
  token list:sym<list> { <sym> }
  token list:sym<l>    { <sym> }
  token list:sym<↪>    { <sym> }

  proto token search { * }
  token search:sym<search> { <sym> }
  token search:sym<s>      { <sym> }
  token search:sym<🌎>     { <sym> }


  proto token help { * }
  token help:sym<help> { <sym> }
  token help:sym<h>    { <sym> }
  token help:sym<ℍ>    { <sym> }
  token help:sym<?>    { <sym> }
  token help:sym<❓>   { <sym> }


  proto token pakkuopt { * }
  token pakkuopt:sym<pretty>   { <pretty> }
  token pakkuopt:sym<async>    { <async> }
  regex pakkuopt:sym<recman>   { <recman> }
  regex pakkuopt:sym<norecman> { <norecman> }
  token pakkuopt:sym<cache>    { <cache> }
  token pakkuopt:sym<yolo>     { <yolo> }
  token pakkuopt:sym<please>   { <sym>    }
  token pakkuopt:sym<dont>     { <sym>    }
  token pakkuopt:sym<verbose>  { <verbose> <.space>* <level> }
  token pakkuopt:sym<config>   { <config>  <.space>* <path> }

  proto token addopt { * }
  token addopt:sym<deps>       { <deps>       }
  token addopt:sym<build>      { <build>      }
  token addopt:sym<test>       { <test>       }
  token addopt:sym<xtest>      { <xtest>      }
  token addopt:sym<force>      { <force>      }
  token addopt:sym<precompile> { <precompile> }
  token addopt:sym<to>         { <sym>     <.space>* <repo> }
  token addopt:sym<exclude>    { <exclude> <.space>* <spec> }

  proto token upgradeopt { * }
  token upgradeopt:sym<deps>       { <deps>       }
  token upgradeopt:sym<build>      { <build>      }
  token upgradeopt:sym<test>       { <test>       }
  token upgradeopt:sym<xtest>      { <xtest>      }
  token upgradeopt:sym<force>      { <force>      }
  token upgradeopt:sym<precompile> { <precompile> }
  token upgradeopt:sym<in>         { <sym>     <.space>* <repo> }
  token upgradeopt:sym<exclude>    { <exclude> <.space>* <spec> }


  proto token downloadopt { * }
  proto token buildopt    { * }

  proto token testopt { * }
  token testopt:sym<build> { <build> }
  token testopt:sym<xtest> { <xtest> }

  proto token removeopt { * }
  token removeopt:sym<from> { <from> <.space>* <repo> }


  proto token listopt { * }
  token listopt:sym<details> { <details> }
  token listopt:sym<repo>    { <sym> <.space>* <repo> }


  proto token searchopt { * }
  token searchopt:sym<details> { <details> }
  token searchopt:sym<count>   { <count> <.space>* <number> }


  proto token pretty { * }
  token pretty:sym<pretty>   { <sym> }
  token pretty:sym<p>        { <sym> }
  token pretty:sym<ℙ>        { <sym> }
  token pretty:sym<℘>        { <sym> }
  token pretty:sym<𝛒>        { <sym> }
  token pretty:sym<nopretty> { <sym> }
  token pretty:sym<np>       { <sym> }


  proto token async { * }
  token async:sym<async>   { <sym> }
  token async:sym<noasync> { <sym> }
  token async:sym<sync>    { <sym> }


  regex recman   { <rec>   | <rec>   <.space>* <recman-name> }
  regex norecman { <norec> | <norec> <.space>* <recman-name> }

  proto token rec { * }
  token rec:sym<recman>   { <sym> }
  token rec:sym<rec>      { <sym> }

  proto token norec { * }
  token norec:sym<norecman> { <sym> }
  token norec:sym<norec>    { <sym> }
  token norec:sym<nrec>     { <sym> }

  proto token cache { * }
  token cache:sym<cache-path> { 'cache' <.space>+ <path> }
  token cache:sym<c-path>     { 'c'     <.space>+ <path> }
  token cache:sym<cache>      { <sym> }
  token cache:sym<c>          { <sym> }
  token cache:sym<nocache>    { <sym> }
  token cache:sym<nc>         { <sym> }

  proto token yolo { * }
  token yolo:sym<yolo>       { <sym> }
  token yolo:sym<y>          { <sym> }
  token yolo:sym<¯\_(ツ)_/¯> { <sym> }


  proto token verbose { * }
  token verbose:sym<verbose> { <sym> }
  token verbose:sym<v>       { <sym> }
  token verbose:sym<𝕧>       { <sym> }
  token verbose:sym<👀>      { <sym> }
  token verbose:sym<👓>      { <sym> }

  proto token config { * }
  token config:sym<config> { <sym> }
  token config:sym<conf>   { <sym> }
  token config:sym<cnf>    { <sym> }

  proto token xtest { * }
  token xtest:sym<xtest>   { <sym> }
  token xtest:sym<xt>      { <sym> }
  token xtest:sym<noxtest> { <sym> }
  token xtest:sym<nxt>     { <sym> }

  proto token deps { * }
  token deps:sym<only>    { <dep> <.space>* <only>    }
  token deps:sym<runtime> { <dep> <.space>* <runtime> }
  token deps:sym<test>    { <dep> <.space>* <tst>    }
  token deps:sym<build>   { <dep> <.space>* <build>   }
  token deps:sym<deps>    { <sym>                     }
  token deps:sym<nodeps>  { <nodeps>                  }

  proto token dep { * }
  token dep:sym<deps>    { <sym> }
  token dep:sym<d>       { <sym> }
  token dep:sym<🔗>      { <sym> }

  proto token nodeps { * }
  token nodeps:sym<nodeps>  { <sym> }
  token nodeps:sym<nd>      { <sym> }

  proto token runtime { * }
  token runtime:sym<runtime> { <sym> }
  token runtime:sym<run>     { <sym> }
  token runtime:sym<rt>      { <sym> }

  proto token tst { * }
  token tst:sym<test> { <sym> }
  token tst:sym<t>    { <sym> }

  proto token requires { * }
  token requires:sym<requires> { <sym> }
  token requires:sym<req>      { <sym> }

  proto token recommends { * }
  token recommends:sym<recommends> { <sym> }
  token recommends:sym<rec>        { <sym> }

  proto token suggests { * }
  token suggests:sym<suggests> { <sym> }
  token suggests:sym<sug>      { <sym> }

  proto token only { * }
  token only:sym<only>   { <sym> }
  token only:sym<o>      { <sym> }

  proto token build { * }
  token build:sym<build>   { <sym> }
  token build:sym<b>       { <sym> }
  token build:sym<nobuild> { <sym> }
  token build:sym<nb>      { <sym> }

  # BUG: need to separate notest
  # pakku nt MyModule
  # parse as cmd => test
  proto token test { * }
  token test:sym<test>   { <sym> }
  token test:sym<t>      { <sym> }
  token test:sym<notest> { <sym> }
  token test:sym<nt>     { <sym> }

  proto token force { * }
  token force:sym<force>   { <sym> }
  token force:sym<f>       { <sym> }
  token force:sym<𝙁>       { <sym> }
  token force:sym<🔨>      { <sym> }
  token force:sym<➟>       { <sym> }
  token force:sym<noforce> { <sym> }
  token force:sym<nf>      { <sym> }

  proto token precompile { * }
  token precompile:sym<precompile>   { <sym> }
  token precompile:sym<precomp>      { <sym> }
  token precompile:sym<p>            { <sym> }
  token precompile:sym<noprecompile> { <sym> }
  token precompile:sym<noprecomp>    { <sym> }
  token precompile:sym<np>           { <sym> }

  proto token exclude { * }
  token exclude:sym<exclude> { <sym> }
  token exclude:sym<x>       { <sym> }

  proto token from { * }
  token from:sym<from> { <sym> }
  token from:sym<f>    { <sym> }

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

  proto token count { * }
  token count:sym<count>   { <sym> }
  token count:sym<c>       { <sym> }

  token repo { <-[\s]>+ }

  token ver { <-[\s]>+ }
   
  token number { <digit>+ }

  proto token level { * }
  token level:sym<SILENT> { <sym> }
  token level:sym<DEBUG>  { <sym> }
  token level:sym<NOW>    { <sym> }
  token level:sym<INFO>   { <sym> }
  token level:sym<WARN>   { <sym> }
  token level:sym<ERROR>  { <sym> }
  token level:sym<silent> { <sym> }
  token level:sym<debug>  { <sym> }
  token level:sym<now>    { <sym> }
  token level:sym<info>   { <sym> }
  token level:sym<warn>   { <sym> }
  token level:sym<error>  { <sym> }
  token level:sym<fatal>  { <sym> }
  token level:sym<S>      { <sym> }
  token level:sym<D>      { <sym> }
  token level:sym<N>      { <sym> }
  token level:sym<I>      { <sym> }
  token level:sym<W>      { <sym> }
  token level:sym<E>      { <sym> }
  token level:sym<0>      { <sym> }
  token level:sym<1>      { <sym> }
  token level:sym<2>      { <sym> }
  token level:sym<3>      { <sym> }
  token level:sym<4>      { <sym> }
  token level:sym<5>      { <sym> }
  token level:sym<42>     { <sym> }
  token level:sym<🐛>     { <sym> }
  token level:sym<🦋>     { <sym> }
  token level:sym<🧚>     { <sym> }
  token level:sym<🐞>     { <sym> }
  token level:sym<🦗>     { <sym> }


  token specs { <spec>+ % \h }

  token spec { <name> <spec-pair>* }
  token path { <[./\\]> <[ a..z A..Z 0..9 \-_.!~*'<>():@&=+$,/\\ ]>* }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token spec-pair { ':' <spec-key> <spec-value> }

  proto token spec-key { * }
  token spec-key:sym<ver>     { <sym> }
  token spec-key:sym<auth>    { <sym> }
  token spec-key:sym<api>     { <sym> }
  token spec-key:sym<from>    { <sym> }
  token spec-key:sym<version> { <sym> }

  proto token spec-value { * }
  token spec-value:sym<angles> { '<' ~ '>' $<val>=[ .*? <~~>? ] }
  token spec-value:sym<parens> { '(' ~ ')' $<val>=[ .*? <~~>? ] }

  token anything { {} .* }

  token lt  { '<' }
  token gt  { '>' }

}

class Pakku::Grammar::CmdActions {

  method TOP:sym<add> ( $/ ) {

    my %cmd;

    %cmd<cmd>       = 'add';
    %cmd<pakku>     = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<add>       = $<addopt>».made.hash   if defined $<addopt>;
    %cmd<add><spec> = $<specs>.made          if defined $<specs>;
    %cmd<add><path> = $<path>.made           if defined $<path>;

    make %cmd;

  }


  method TOP:sym<upgrade> ( $/ ) {

    my %cmd;

    %cmd<cmd>           = 'upgrade';
    %cmd<pakku>         = $<pakkuopt>».made.hash   if defined $<pakkuopt>;
    %cmd<upgrade>       = $<upgradeopt>».made.hash if defined $<upgradeopt>;
    %cmd<upgrade><spec> = $<specs>.made;

    make %cmd;

  }

  method TOP:sym<build> ( $/ ) {

    my %cmd;

    %cmd<cmd>         = 'build';
    %cmd<pakku>       = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<build>       = $<buildopt>».made.hash if defined $<buildopt>;
    %cmd<build><spec> = $<spec>.made if defined $<spec>;
    %cmd<build><path> = $<path>.made if defined $<path>;

    make %cmd;

  }

  method TOP:sym<test> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'test';
    %cmd<pakku>      = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<test>       = $<testopt>».made.hash  if defined $<testopt>;
    %cmd<test><spec> = $<spec>.made           if defined $<spec>;
    %cmd<test><path> = $<path>.made           if defined $<path>;

    make %cmd;

  }


  method TOP:sym<remove> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'remove';
    %cmd<pakku>        = $<pakkuopt>».made.hash  if defined $<pakkuopt>;
    %cmd<remove>       = $<removeopt>».made.hash if defined $<removeopt>;
    %cmd<remove><spec> = $<specs>.made;

    make %cmd;

  }

  method TOP:sym<download> ( $/ ) {

    my %cmd;

    %cmd<cmd>            = 'download';
    %cmd<pakku>          = $<pakkuopt>».made.hash     if defined $<pakkuopt>;
    %cmd<download>       = $<downloadopt>».made.hash  if defined $<downloadopt>;
    %cmd<download><spec> = $<specs>.made;

    make %cmd;

  }


  method TOP:sym<list> ( $/ ) {

    my %cmd;

    %cmd<cmd>        = 'list';
    %cmd<pakku>      = $<pakkuopt>».made.hash if defined $<pakkuopt>;
    %cmd<list>       = $<listopt>».made.hash  if defined $<listopt>;
    %cmd<list><spec> = $<specs>.made          if defined $<specs>;

    make %cmd;

  }


  method TOP:sym<search> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'search';
    %cmd<pakku>        = $<pakkuopt>».made.hash   if defined $<pakkuopt>;
    %cmd<search>       = $<searchopt>».made.hash  if defined $<searchopt>;
    %cmd<search><spec> = $<specs>.made;

    make %cmd;

  }

  method TOP:sym<config> ( $/ ) {

    my %cmd;

    %cmd<cmd>          = 'config';
    %cmd<pakku>        = $<pakkuopt>».made.hash   if defined $<pakkuopt>;
    %cmd<config>       = $<config-cmd>.made.hash  if defined $<config-cmd>;

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
  method cmd:sym<upgrade>  ( $/ ) { make 'upgrade'  }
  method cmd:sym<build>    ( $/ ) { make 'build'    }
  method cmd:sym<test>     ( $/ ) { make 'test'     }
  method cmd:sym<remove>   ( $/ ) { make 'remove'   }
  method cmd:sym<download> ( $/ ) { make 'download' }
  method cmd:sym<list>     ( $/ ) { make 'list'     }
  method cmd:sym<search>   ( $/ ) { make 'search'   }
  method cmd:sym<config>   ( $/ ) { make 'config'   }
  method cmd:sym<help>     ( $/ ) { make 'help'     }


  method config-cmd:sym<config-view>( $/ ) { 
    make %( :operation<view> )
  }

  method config-cmd:sym<config-new>( $/ ) {
    make  %( operation =>  ~$<config-new> )
  }

  method config-cmd:sym<config-reset>( $/ ) {
    make %( operation => ~$<reset> )
  }

  method config-cmd:sym<config-module-view>( $/ ) {
    make %( :operation<view>, module => ~$<config-module-any> )
  }

  method config-cmd:sym<config-module-reset>( $/ ) {
    make %(
      module    => ~$<config-module-any>,
      operation => ~$<reset>,
    )
  }

  method config-cmd:sym<config-module-unset>( $/ ) {
    make %(
      module    => ~$<config-module-any>,
      operation => ~$<unset>,
    )
  }

  method config-cmd:sym<config-recman-name-view-option>( $/ ) {

    my Str @option = @<key-option>.map( ~* ); 

    make %(
      module    => ~$<config-module-recman>,
      operation => 'view',
      recman-name => ~$<recman-name>,
      :@option,
    )
  }

  method config-cmd:sym<config-log-level-view-option>( $/ ) {

    my Str @option = @<key-option>.map( ~* ); 

    make %(
      module    => ~$<config-module-log>,
      operation => 'view',
      log-level => ~$<log-level>,
      :@option,
    )
  }

  method config-cmd:sym<config-recman-name-view>( $/ ) {

    make %(
      module    => ~$<config-module-recman>,
      operation => 'view',
      recman-name => ~$<recman-name>,
    )
  }

  method config-cmd:sym<config-log-level-view>( $/ ) {

    make %(
      module    => ~$<config-module-log>,
      operation => 'view',
      log-level => ~$<log-level>,
    )
  }



  method config-cmd:sym<config-module-view-option>( $/ ) {

    my Str @option = @<key-option>.map( ~* ); 

    make %(
      module    => ~$<config-module>,
      operation => 'view',
      :@option,
    )
  }

  method config-cmd:sym<config-module-unset-option>( $/ ) {

    my Pair @option = @<key-option>.map( ~* => Nil ); 

    make %(
      module    => ~$<config-module>,
      :@option,
    )
  }

  method config-cmd:sym<config-module-disable>( $/ ) {

    my Pair @option = @<key-option>.map( ~* => False ); 

    make %(
      module    => ~$<config-module>,
      :@option,
    )
  }

  method config-cmd:sym<config-module-enable>( $/ ) {

    my Pair @option = @<key-option>.map( ~* => True ); 

    make %(
      module    => ~$<config-module>,
      :@option,
    )
  }

  method config-cmd:sym<config-module-set>( $/ ) {

    my Pair @option = @<keyval-option>.map( { ~.<key> => ~.<value> } ); 

    make %(
      module    => ~$<config-module>,
      :@option,
    )
  }

  method config-cmd:sym<config-module-recman-set>( $/ ) {

    my Pair @option = @<keyval-option>.map( { ~.<key> => ~.<value> } ); 

    make %(
      module      => ~$<config-module-recman>,
      recman-name => ~$<recman-name>, 
      :@option,
    )
  }


  method config-cmd:sym<config-module-recman-enable>( $/ ) {
    make %(
      module      => ~$<config-module-recman>,
      operation   => ~$<enable>, 
      recman-name => ~$<recman-name>, 
    )
  }

  method config-cmd:sym<config-module-recman-disable>( $/ ) {
    make %(
      module      => ~$<config-module-recman>,
      operation   => ~$<disable>, 
      recman-name => ~$<recman-name>, 
    )
  }

  method config-cmd:sym<config-module-recman-unset>( $/ ) {
    make %(
      module      => ~$<config-module-recman>,
      operation   => ~$<unset>, 
      recman-name => ~$<recman-name>, 
    )
  }

  method config-cmd:sym<config-module-log-set>( $/ ) {
    make %(
      module    => ~$<config-module-log>,
      operation => ~$<set>, 
      log-level => ~$<log-level>, 
      option    => @<log-level-option>.map( { ~.<sym> => ~.<value> } ).Array, 
    )
  }

  method config-cmd:sym<config-module-log-unset>( $/ ) {
    make %(
      module    => ~$<config-module-log>,
      operation => ~$<unset>, 
      log-level => ~$<log-level>, 
    )
  }

  method pakkuopt:sym<pretty>   ( $/ ) { make $<pretty>.made               }
  method pakkuopt:sym<async>    ( $/ ) { make $<async>.made                }
  method pakkuopt:sym<recman>   ( $/ ) { make $<recman>.made               }
  method pakkuopt:sym<norecman> ( $/ ) { make $<norecman>.made               }
  method pakkuopt:sym<cache>    ( $/ ) { make $<cache>.made                }
  method pakkuopt:sym<yolo>     ( $/ ) { make ( :yolo )                    }
  method pakkuopt:sym<please>   ( $/ ) { make ( :please )                  }
  method pakkuopt:sym<dont>     ( $/ ) { make ( :dont )                    }
  method pakkuopt:sym<verbose>  ( $/ ) { make ( verbose => $<level>.made ) }
  method pakkuopt:sym<config>   ( $/ ) { make ( config  => $<path>.made  ) }

  method addopt:sym<deps>       ( $/ ) { make $<deps>.made       }
  method addopt:sym<build>      ( $/ ) { make $<build>.made      }
  method addopt:sym<test>       ( $/ ) { make $<test>.made       }
  method addopt:sym<xtest>      ( $/ ) { make $<xtest>.made      }
  method addopt:sym<force>      ( $/ ) { make $<force>.made      }
  method addopt:sym<precompile> ( $/ ) { make $<precompile>.made }
  method addopt:sym<to>         ( $/ ) { make ( to => $<repo>.Str ) }
  method addopt:sym<exclude>    ( $/ ) { @*exclude.push: $<spec>.made; make ( exclude => @*exclude ) }


  method upgradeopt:sym<deps>       ( $/ ) { make $<deps>.made  }
  method upgradeopt:sym<build>      ( $/ ) { make $<build>.made }
  method upgradeopt:sym<test>       ( $/ ) { make $<test>.made  }
  method upgradeopt:sym<xtest>      ( $/ ) { make $<xtest>.made }
  method upgradeopt:sym<force>      ( $/ ) { make $<force>.made }
  method upgradeopt:sym<precompile> ( $/ ) { make $<precompile>.made }
  method upgradeopt:sym<in>         ( $/ ) { make ( in => $<repo>.Str ) }
  method upgradeopt:sym<exclude>    ( $/ ) { @*exclude.push: $<spec>.made; make ( exclude => @*exclude ) }


  method removeopt:sym<from> ( $/ ) { make ( from => $<repo>.Str ) }

  method testopt:sym<build> ( $/ ) { make $<build>.made }
  method testopt:sym<xtest> ( $/ ) { make $<xtest>.made }

  method listopt:sym<details> ( $/ ) { make $<details>.made }

  method listopt:sym<repo> ( $/ ) { make ( repo => $<repo>.Str ) }

  method searchopt:sym<details> ( $/ ) { make $<details>.made }
  method searchopt:sym<count>   ( $/ ) { make ( count => +$<number> ) }

  method deps:sym<only>    ( $/ )  { make ( deps => 'only' )    }
  method deps:sym<runtime> ( $/ )  { make ( deps => 'runtime' ) }
  method deps:sym<test>    ( $/ )  { make ( deps => 'test' )    }
  method deps:sym<build>   ( $/ )  { make ( deps => 'build' )   }
  method deps:sym<deps>    ( $/ )  { make ( :deps )             }
  method deps:sym<nodeps>  ( $/ )  { make ( :!deps )            }

  method pretty:sym<pretty>   ( $/ )  { make ( :pretty  ) }
  method pretty:sym<p>        ( $/ )  { make ( :pretty  ) }
  method pretty:sym<ℙ>        ( $/ )  { make ( :pretty  ) }
  method pretty:sym<𝛒>        ( $/ )  { make ( :pretty  ) }
  method pretty:sym<℘>        ( $/ )  { make ( :pretty  ) }
  method pretty:sym<nopretty> ( $/ )  { make ( :!pretty ) }
  method pretty:sym<np>       ( $/ )  { make ( :!pretty ) }

  method async:sym<async>   ( $/ )  { make ( :async  ) }
  method async:sym<noasync> ( $/ )  { make ( :!async ) }
  method async:sym<sync>    ( $/ )  { make ( :!async ) }

  method recman   ( $/ )  { make ( $<recman-name> ?? :recman(   ~$<recman-name> ) !! :recman   ) }
  method norecman ( $/ )  { make ( $<recman-name> ?? :norecman( ~$<recman-name> ) !! :norecman ) }

  method recman:sym<norecman> ( $/ )  { make ( :!recman ) }
  method recman:sym<nr>       ( $/ )  { make ( :!recman ) }

  method cache:sym<cache-path>   ( $/ )  { make ( cache => $<path>.made ) }
  method cache:sym<c-path>       ( $/ )  { make ( cache => $<path>.made ) }
  method cache:sym<cache> ( $/ )  { make ( :cache ) }
  method cache:sym<c>     ( $/ )  { make ( :cache ) }
  method cache:sym<nocache> ( $/ )  { make ( :!cache ) }
  method cache:sym<nc>      ( $/ )  { make ( :!cache ) }

  method build:sym<build>   ( $/ )  { make ( :build  ) }
  method build:sym<b>       ( $/ )  { make ( :build  ) }
  method build:sym<nobuild> ( $/ )  { make ( :!build ) }
  method build:sym<nb>      ( $/ )  { make ( :!build ) }

  method test:sym<test>   ( $/ )  { make ( :test  ) }
  method test:sym<t>      ( $/ )  { make ( :test  ) }
  method test:sym<notest> ( $/ )  { make ( :!test ) }
  method test:sym<nt>     ( $/ )  { make ( :!test ) }

  method xtest:sym<xtest>   ( $/ )  { make ( :xtest  ) }
  method xtest:sym<xt>      ( $/ )  { make ( :xtest  ) }
  method xtest:sym<noxtest> ( $/ )  { make ( :!xtest ) }
  method xtest:sym<nxt>     ( $/ )  { make ( :!xtest ) }

  method force:sym<force>   ( $/ )  { make ( :force  ) }
  method force:sym<f>       ( $/ )  { make ( :force  ) }
  method force:sym<𝙁>       ( $/ )  { make ( :force  ) }
  method force:sym<🔨>      ( $/ )  { make ( :force  ) }
  method force:sym<➟>       ( $/ )  { make ( :force  ) }
  method force:sym<noforce> ( $/ )  { make ( :!force ) }
  method force:sym<nf>      ( $/ )  { make ( :!force ) }

  method precompile:sym<precompile>   ( $/ )  { make ( :precompile  ) }
  method precompile:sym<precomp>      ( $/ )  { make ( :precompile  ) }
  method precompile:sym<noprecompile> ( $/ )  { make ( :!precompile ) }
  method precompile:sym<noprecomp>    ( $/ )  { make ( :!precompile ) }
  method precompile:sym<np>           ( $/ )  { make ( :!precompile ) }

  method remote:sym<remote>   ( $/ )  { make ( :remote  ) }
  method remote:sym<r>        ( $/ )  { make ( :remote  ) }
  method remote:sym<🌎>       ( $/ )  { make ( :remote  ) }
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

  method level:sym<SILENT> ( $/ ) { make 'silent' }
  method level:sym<DEBUG>  ( $/ ) { make 'debug'  }
  method level:sym<NOW>    ( $/ ) { make 'now'    }
  method level:sym<INFO>   ( $/ ) { make 'info'   }
  method level:sym<WARN>   ( $/ ) { make 'warn'   }
  method level:sym<ERROR>  ( $/ ) { make 'error'  }
  method level:sym<silent> ( $/ ) { make 'silent' }
  method level:sym<debug>  ( $/ ) { make 'debug'  }
  method level:sym<now>    ( $/ ) { make 'now'    }
  method level:sym<info>   ( $/ ) { make 'info'   }
  method level:sym<warn>   ( $/ ) { make 'warn'   }
  method level:sym<error>  ( $/ ) { make 'error'  }
  method level:sym<S>      ( $/ ) { make 'silent' }
  method level:sym<D>      ( $/ ) { make 'debug'  }
  method level:sym<N>      ( $/ ) { make 'now'    }
  method level:sym<I>      ( $/ ) { make 'info'   }
  method level:sym<W>      ( $/ ) { make 'warn'   }
  method level:sym<E>      ( $/ ) { make 'error'  }
  method level:sym<0>      ( $/ ) { make 'silent' }
  method level:sym<1>      ( $/ ) { make 'debug'  }
  method level:sym<2>      ( $/ ) { make 'now'    }
  method level:sym<3>      ( $/ ) { make 'info'   }
  method level:sym<4>      ( $/ ) { make 'warn'   }
  method level:sym<5>      ( $/ ) { make 'error'  }
  method level:sym<42>     ( $/ ) { make 'debug'  }
  method level:sym<🐛>     ( $/ ) { make 'debug'  }
  method level:sym<🦋>     ( $/ ) { make 'now'    }
  method level:sym<🧚>     ( $/ ) { make 'info'   }
  method level:sym<🐞>     ( $/ ) { make 'warn'   }
  method level:sym<🦗>     ( $/ ) { make 'error'  }

  method specs ( $/ ) { make $<spec>».made }

  method spec ( $/ ) { make $/.Str }

  method path ( $/ ) { make $/.IO }

}
