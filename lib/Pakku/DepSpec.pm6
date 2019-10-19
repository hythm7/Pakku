use X::Pakku;
use Pakku::DepSpec::Perl6;
use Pakku::DepSpec::Perl5;
use Pakku::DepSpec::Bin;
use Pakku::DepSpec::Native;
use Pakku::DepSpec::Java;


unit class Pakku::DepSpec;
  also is CompUnit::DependencySpecification;


grammar SpecGrammar {

  token TOP { <spec> }

  token spec { <name> <keyval>* }

  token name { [<-[/:<>()\h]>+]+ % '::' }

  token keyval { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<author>  { <sym> }
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

  # TODO Make it work with Regex matchers
  method spec ( $/ ) {
    my %id;

    %id<name> = $<name>.Str;
    %id.push: ( $<keyval>».ast ) if $<keyval>;

    my %spec;

    %spec<short-name>      = %id<name> if %id<name>;
    %spec<version-matcher> = Version.new( %id<ver>  // %id<version> ) if %id<ver> // %id<version>;
    %spec<auth-matcher>    = %id<auth> // %id<author> if %id<auth> // %id<author>;
    %spec<api-matcher>     = %id<api>  if %id<api>;
    %spec<from>            = %id<from> // 'Perl6';

    make %spec;

  }

  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }

  method value:sym<angles> ( $/ )  { make $<val>.Str }
  method value:sym<parens> ( $/ )  { make $<val>.Str }

}


multi method new ( %spec ) {

  return self.depspec: %spec if %spec<from>;

  my %parsed = self.parse: %spec<name> if %spec<name> ~~ Str;

  self.depspec: %( %spec, %parsed );

}


multi method new ( Str $spec ) {

  my %spec = self.parse: $spec;

  self.depspec: %spec;

}

method parse ( Str $spec --> Hash ) {

  my $grammar = SpecGrammar;
  my $actions = SpecActions;

  my $m = $grammar.parse( $spec, :$actions );

  die X::Pakku::DepSpec::CannotParse.new( :$spec ) unless $m;

  $m.ast;

}

method depspec ( %spec ) {

  given %spec<from> {

    when 'Perl6' {
      Pakku::DepSpec::Perl6.new: %spec;
    }

    when 'Perl5' {
      Pakku::DepSpec::Perl5.new: %spec;
    }

    when 'bin' {
      Pakku::DepSpec::Bin.new: %spec;
    }

    when 'native' {
      Pakku::DepSpec::Native.new: %spec;
    }

    when 'java' {
      Pakku::DepSpec::Java.new: %spec;
    }

  }

}


