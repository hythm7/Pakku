use X::Pakku;
use Pakku::DepSpec::Perl6;
use Pakku::DepSpec::Perl5;
use Pakku::DepSpec::Bin;
use Pakku::DepSpec::Native;
use Pakku::DepSpec::Java;


unit class Pakku::DepSpec;
  also is CompUnit::DependencySpecification;


grammar SpecGrammar {

  token TOP { <depspec> }

  token depspec { <name> <keyval>* }

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

  method TOP ( $/ ) { make $<depspec>.ast }

  method depspec ( $/ ) {
    my %id;

    %id<name> = $<name>.Str;
    %id.push: ( $<keyval>».ast ) if $<keyval>;

    my %depspec;

    %depspec<short-name>      = %id<name> if %id<name>;
    %depspec<auth-matcher>    = %id<auth> if %id<auth>;
    %depspec<api-matcher>     = %id<api>  if %id<api>;
    %depspec<from>            = %id<from> // 'Perl6';
    %depspec<version-matcher> = %id<ver>  // %id<version> if %id<ver> // %id<version>;

    make %depspec;

  }

  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }

  method value:sym<angles> ( $/ )  { make $<val>.Str }
  method value:sym<parens> ( $/ )  { make $<val>.Str }

}


multi method new ( %depspec ) {

  return self.depspec: %depspec if %depspec<from>;

  my %parsed = self.parse: %depspec<name> if %depspec<name> ~~ Str;

  self.depspec: %( %depspec, %parsed );

}


multi method new ( Str $depspec ) {

  my %depspec = self.parse: $depspec;

  self.depspec: %depspec;

}

method parse ( Str $depspec --> Hash ) {

  my $grammar = SpecGrammar;
  my $actions = SpecActions;

  my $m = $grammar.parse( $depspec, :$actions );

  die X::Pakku::DepSpec::CannotParse.new( depspec => $depspec ) unless $m;

  $m.ast;

}

method depspec ( %depspec ) {

  given %depspec<from> {

    when 'Perl6' {
      Pakku::DepSpec::Perl6.new: |%depspec;
    }

    when 'Perl5' {
      Pakku::DepSpec::Perl5.new: |%depspec;
    }

    when 'bin' {
      Pakku::DepSpec::Bin.new: |%depspec;
    }

    when 'native' {
      Pakku::DepSpec::Native.new: |%depspec;
    }

    when 'java' {
      Pakku::DepSpec::Java.new: |%depspec;
    }

  }

}


