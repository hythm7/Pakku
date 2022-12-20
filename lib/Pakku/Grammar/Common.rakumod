role Pakku::Grammar::Common {

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
  token pakkuopt:sym<pretty>  { <pretty> }
  token pakkuopt:sym<async>   { <async> }
  token pakkuopt:sym<recman>  { <recman> }
  token pakkuopt:sym<cache>   { <cache> }
  token pakkuopt:sym<yolo>    { <yolo> }
  token pakkuopt:sym<please>  { <sym>    }
  token pakkuopt:sym<dont>    { <sym>    }
  token pakkuopt:sym<verbose> { <verbose> <.space>* <level> }
  token pakkuopt:sym<config>  { <config>  <.space>* <path> }

  proto token addopt { * }
  token addopt:sym<deps-only>  { <deps> <.space>* <only>    } # needed before <deps> (LTM)
  token addopt:sym<deps>       { <deps>       }
  token addopt:sym<nodeps>     { <nodeps>     }
  token addopt:sym<build>      { <build>      }
  token addopt:sym<test>       { <test>       }
  token addopt:sym<xtest>      { <xtest>      }
  token addopt:sym<force>      { <force>      }
  token addopt:sym<precompile> { <precompile> }
  token addopt:sym<to>         { <sym>     <.space>* <repo> }
  token addopt:sym<exclude>    { <exclude> <.space>* <spec> }

  proto token upgradeopt { * }
  token upgradeopt:sym<deps>       { <deps>       }
  token upgradeopt:sym<nodeps>     { <nodeps>     }
  token upgradeopt:sym<build>      { <build>      }
  token upgradeopt:sym<test>       { <test>       }
  token upgradeopt:sym<xtest>      { <xtest>      }
  token upgradeopt:sym<force>      { <force>      }
  token upgradeopt:sym<precompile> { <precompile> }
  token upgradeopt:sym<deps-only>  { <deps> <.space>* <only>    }
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


  proto token recman { * }
  token recman:sym<recman>   { <sym> }
  token recman:sym<r>        { <sym> }
  token recman:sym<norecman> { <sym> }
  token recman:sym<nr>       { <sym> }

  proto token cache { * }
  token cache:sym<cache>   { <sym> }
  token cache:sym<c>       { <sym> }
  token cache:sym<nocache> { <sym> }
  token cache:sym<nc>      { <sym> }

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
  token deps:sym<deps>   { <sym> }
  token deps:sym<d>      { <sym> }
  token deps:sym<🔗>     { <sym> }

  proto token nodeps { * }
  token nodeps:sym<nodeps> { <sym> }
  token nodeps:sym<nd>     { <sym> }

  proto token run { * }
  token run:sym<runtime> { <sym> }
  token run:sym<run>     { <sym> }

  #proto token tst { * }
  #token tst:sym<test> { <sym> }
  #token tst:sym<tst>  { <sym> }

  #proto token bld { * }
  #token bld:sym<build> { <sym> }
  #token bld:sym<bld>   { <sym> }

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

  proto token repo { * }
  token repo:sym<home>   { <sym>    }
  token repo:sym<site>   { <sym>    }
  token repo:sym<vendor> { <sym>    }
  token repo:sym<core>   { <sym>    }
  token repo:sym<spec>   { <-[\s]>+ }

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


  token whats { <what>+ % \h }

  proto token what { * }
  token what:sym<spec> {    <spec> }
  token what:sym<path> { {} <path> }

  token spec { <name> <spec-pair>* }
  token path { <[ a..z A..Z 0..9 \-_.!~*'<>():@&=+$,/ ]>+ }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token spec-pair { ':' <spec-key> <value> }

  proto token spec-key { * }
  token spec-key:sym<ver>     { <sym> }
  token spec-key:sym<auth>    { <sym> }
  token spec-key:sym<api>     { <sym> }
  token spec-key:sym<from>    { <sym> }
  token spec-key:sym<version> { <sym> }

  proto token value { * }
  token value:sym<angles> { '<' ~ '>' $<val>=[ .*? <~~>? ] }
  token value:sym<parens> { '(' ~ ')' $<val>=[ .*? <~~>? ] }

  token anything { {} .* }

  token lt  { '<' }
  token gt  { '>' }
}

role Pakku::Grammar::CommonActions {

  method pakkuopt:sym<pretty>  ( $/ ) { make $<pretty>.made               }
  method pakkuopt:sym<async>   ( $/ ) { make $<async>.made                }
  method pakkuopt:sym<recman>  ( $/ ) { make $<recman>.made               }
  method pakkuopt:sym<cache>   ( $/ ) { make $<cache>.made                }
  method pakkuopt:sym<yolo>    ( $/ ) { make ( :yolo )                    }
  method pakkuopt:sym<please>  ( $/ ) { make ( :please )                  }
  method pakkuopt:sym<dont>    ( $/ ) { make ( :dont )                    }
  method pakkuopt:sym<verbose> ( $/ ) { make ( verbose => $<level>.made ) }
  method pakkuopt:sym<config>  ( $/ ) { make ( config  => $<path>.made  ) }

  method addopt:sym<deps>       ( $/ ) { make ( :deps       )    }
  method addopt:sym<nodeps>     ( $/ ) { make ( :!deps      )    }
  method addopt:sym<deps-only>  ( $/ ) { make ( :deps<only> )    }
  method addopt:sym<build>      ( $/ ) { make $<build>.made      }
  method addopt:sym<test>       ( $/ ) { make $<test>.made       }
  method addopt:sym<xtest>      ( $/ ) { make $<xtest>.made      }
  method addopt:sym<force>      ( $/ ) { make $<force>.made      }
  method addopt:sym<precompile> ( $/ ) { make $<precompile>.made }
  method addopt:sym<to>         ( $/ ) { make ( repo => $<repo>.made ) }
  method addopt:sym<exclude>    ( $/ ) { make ( exclude => $<spec>.made ) }


  method upgradeopt:sym<deps>      ( $/ )  { make ( :deps       ) }
  method upgradeopt:sym<nodeps>    ( $/ )  { make ( :!deps      ) }
  method upgradeopt:sym<deps-only> ( $/ )  { make ( :deps<only> ) }
  method upgradeopt:sym<build>     ( $/ )  { make $<build>.made }
  method upgradeopt:sym<test>      ( $/ )  { make $<test>.made  }
  method upgradeopt:sym<xtest>     ( $/ )  { make $<xtest>.made }
  method upgradeopt:sym<force>     ( $/ )  { make $<force>.made }
  method upgradeopt:sym<precompile> ( $/ ) { make $<precompile>.made }
  method upgradeopt:sym<in>        ( $/ )  { make ( repo => $<repo>.made ) }
  method upgradeopt:sym<exclude>   ( $/ )  { make ( exclude => $<spec>.made ) }


  method removeopt:sym<from> ( $/ ) { make ( repo => $<repo>.made ) }

  method testopt:sym<build> ( $/ ) { make $<build>.made }
  method testopt:sym<xtest> ( $/ ) { make $<xtest>.made }

  method listopt:sym<details> ( $/ ) { make $<details>.made }

  method listopt:sym<repo> ( $/ ) { make ( repo => $<repo>.made ) }

  method searchopt:sym<details> ( $/ ) { make $<details>.made }
  method searchopt:sym<count>   ( $/ ) { make ( count => +$<number> ) }

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

  method recman:sym<recman>   ( $/ )  { make ( :recman  ) }
  method recman:sym<r>        ( $/ )  { make ( :recman  ) }
  method recman:sym<norecman> ( $/ )  { make ( :!recman ) }
  method recman:sym<nr>       ( $/ )  { make ( :!recman ) }

  method cache:sym<cache>   ( $/ )  { make ( :cache  ) }
  method cache:sym<c>       ( $/ )  { make ( :cache  ) }
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

  method repo:sym<home>   ( $/ ) { make CompUnit::RepositoryRegistry.repository-for-name( ~$/ ) }
  method repo:sym<site>   ( $/ ) { make CompUnit::RepositoryRegistry.repository-for-name( ~$/ ) }
  method repo:sym<vendor> ( $/ ) { make CompUnit::RepositoryRegistry.repository-for-name( ~$/ ) }
  method repo:sym<core>   ( $/ ) { make CompUnit::RepositoryRegistry.repository-for-name( ~$/ ) }
  method repo:sym<spec>   ( $/ ) {

	  my $spec = CompUnit::Repository::Spec.from-string( ~$/, 'inst' );
		# CURS requires name
		my $name = $spec.options<name> // 'custom-lib';
		my $repo = CompUnit::RepositoryRegistry.repository-for-spec( $spec );

		CompUnit::RepositoryRegistry.register-name( $name, $repo );

		make $repo;
	}

  method level:sym<SILENT> ( $/ ) { make 0 }
  method level:sym<DEBUG>  ( $/ ) { make 1 }
  method level:sym<NOW>    ( $/ ) { make 2 }
  method level:sym<INFO>   ( $/ ) { make 3 }
  method level:sym<WARN>   ( $/ ) { make 4 }
  method level:sym<ERROR>  ( $/ ) { make 5 }
  method level:sym<silent> ( $/ ) { make 0 }
  method level:sym<debug>  ( $/ ) { make 1 }
  method level:sym<now>    ( $/ ) { make 2 }
  method level:sym<info>   ( $/ ) { make 3 }
  method level:sym<warn>   ( $/ ) { make 4 }
  method level:sym<error>  ( $/ ) { make 5 }
  method level:sym<S>      ( $/ ) { make 0 }
  method level:sym<D>      ( $/ ) { make 1 }
  method level:sym<N>      ( $/ ) { make 2 }
  method level:sym<I>      ( $/ ) { make 3 }
  method level:sym<W>      ( $/ ) { make 4 }
  method level:sym<E>      ( $/ ) { make 5 }
  method level:sym<0>      ( $/ ) { make 0 }
  method level:sym<1>      ( $/ ) { make 1 }
  method level:sym<2>      ( $/ ) { make 2 }
  method level:sym<3>      ( $/ ) { make 3 }
  method level:sym<4>      ( $/ ) { make 4 }
  method level:sym<5>      ( $/ ) { make 5 }
  method level:sym<42>     ( $/ ) { make 1 }
  method level:sym<🐛>     ( $/ ) { make 1 }
  method level:sym<🦋>     ( $/ ) { make 2 }
  method level:sym<🧚>     ( $/ ) { make 3 }
  method level:sym<🐞>     ( $/ ) { make 4 }
  method level:sym<🦗>     ( $/ ) { make 5 }

  method whats ( $/ ) { make $<what>».made }

  method what:sym<spec> ( $/ ) { make $<spec>.made }
  method what:sym<path> ( $/ ) { make $<path>.made }

  method spec ( $/ ) { make $/.Str }

  method path ( $/ ) { make $/.IO }

}
