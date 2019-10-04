use X::Pakku;
use Pakku::Spec::Perl6;
use Pakku::Spec::Perl5;
use Pakku::Spec::Bin;
use Pakku::Spec::Native;
use Pakku::Spec::Java;


unit class Pakku::Spec;
  also is CompUnit::DependencySpecification;


grammar SpecGrammar {

  token TOP { <spec> }

  token spec { <name> <keyval>* }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token keyval { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<api>     { <sym> }
  token key:sym<from>    { <sym> }
  token key:sym<version> { <sym> }

  # Thx to Jo King on SO.
  proto token value { * }
  token value:sym<angles> { '<' ~ '>' $<val>=[.*? <~~>?] }
  token value:sym<parens> { '(' ~ ')' $<val>=[.*? <~~>?] }


}

class SpecActions {

  method TOP ( $/ ) { make $<spec>.ast }

  method spec ( $/ ) {
    my %id;

    %id<name> = $<name>.Str;
    %id.push: ( $<keyval>».ast ) if $<keyval>;

    my %spec;

    %spec<short-name>      = %id<name> if %id<name>;
    %spec<auth-matcher>    = %id<auth> if %id<auth>;
    %spec<api-matcher>     = %id<api>  if %id<api>;
    %spec<from>            = %id<from> // 'Perl6';
    %spec<version-matcher> = %id<ver>  // %id<version> if %id<ver> // %id<version>;

    make %spec;

  }

  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }

  method value:sym<angles> ( $/ )  { make $<val>.Str }
  method value:sym<parens> ( $/ )  { make $<val>.Str }

}

multi method new ( Str $depspec ) {

  self.new: %( name => $depspec );

}

multi method new ( %depspec ) {

  my $grammar = SpecGrammar;
  my $actions = SpecActions;

  my $m = $grammar.parse( %depspec<name>, :$actions );

  die X::Pakku::Spec::CannotParse.new( spec => %depspec<name> ) unless $m;

  my %parsed = $m.ast;

  given %parsed<from> {


    when 'Perl6' {
      Pakku::Spec::Perl6.new: |%parsed, |%depspec;
    }

    when 'Perl5' {
      Pakku::Spec::Perl5.new: |%parsed, |%depspec;
    }

    when 'Bin' {
      Pakku::Spec::Bin.new: |%parsed, |%depspec;
    }

    when 'Native' {
      Pakku::Spec::Native.new: |%parsed, |%depspec;
    }

    when 'Java' {
      Pakku::Spec::Java.new: |%parsed, |%depspec;
    }


  }





}


