use experimental :rakuast;
use MONKEY-SEE-NO-EVAL;

use X::Pakku;
use Pakku::Util;

# Dependency specifications, with Raku's own semantics (S11, S22):
#   Foo:ver<1.2+>:auth<zef:x>:api<1>   <...> is a string: Version / auth rules of Rakudo
#   Foo:ver(* > 0.2):auth(/^zef/)      (...) is code: any smartmatch selector
#   { "name": "Foo", "ver": "1.2+" }   hash form, name may carry adverbs
#   { "any": [ ... ] }                 alternatives, recursive
# Selectors are parsed with Rakudo's own parser (RakuAST), reduced to a
# whitelist of literal/operator nodes, then evaluated; matching is plain ~~.

# numbers inside a selector mean versions: :ver(* > 0.2)
my multi sub infix:«>»  ( Version:D \a, Numeric:D \b ) { a >  Version.new( ~b ) }
my multi sub infix:«>=» ( Version:D \a, Numeric:D \b ) { a >= Version.new( ~b ) }
my multi sub infix:«<»  ( Version:D \a, Numeric:D \b ) { a <  Version.new( ~b ) }
my multi sub infix:«<=» ( Version:D \a, Numeric:D \b ) { a <= Version.new( ~b ) }
my multi sub infix:«==» ( Version:D \a, Numeric:D \b ) { a == Version.new( ~b ) }
my multi sub infix:«!=» ( Version:D \a, Numeric:D \b ) { a != Version.new( ~b ) }

my constant @INFIX = '..', '..^', '^..', '^..^', '<', '<=', '>', '>=', '==', '!=',
                     'eq', 'ne', 'lt', 'le', 'gt', 'ge', '|', '&', '^', '&&', '||';

my sub validate ( $node, Str:D $text --> Nil ) {

  my sub refuse ( Str $why ) { die X::Pakku::Spec.new: msg => "($text)", comment => "$why: not a version/auth/api selector" }

  given $node {
    when RakuAST::StatementList                 { refuse 'more than one statement' unless .statements == 1 }
    when RakuAST::Statement::Expression         { }
    when RakuAST::ApplyInfix                    { }
    when RakuAST::ApplyListInfix                { }
    when RakuAST::Infix                         { refuse "operator { .operator }" unless .operator eq any @INFIX }
    when RakuAST::ApplyPrefix                   { }
    when RakuAST::Prefix                        { refuse "operator { .operator }" unless .operator eq '!' }
    when RakuAST::ArgList                       { }
    when RakuAST::WhateverCode::Argument        { }
    when RakuAST::Term::Whatever                { }
    when RakuAST::VersionLiteral                { }
    when RakuAST::IntLiteral                    { }
    when RakuAST::RatLiteral                    { }
    when RakuAST::NumLiteral                    { }
    when RakuAST::StrLiteral                    { }
    when RakuAST::QuotedString                  { }
    when RakuAST::QuotedRegex                   { }
    when RakuAST::Circumfix::Parentheses        { }
    when RakuAST::SemiList                      { }
    when RakuAST::Type::Simple                  { refuse "type { .name.canonicalize }" unless .name.canonicalize eq 'Any' }
    when RakuAST::Call::Name                    { refuse "call to { .name.canonicalize }" unless .name.canonicalize eq any <any all one none> }
    when RakuAST::Name                          { }
    default                                     { refuse .^name.subst( 'RakuAST::', '' ) unless .^name.starts-with( 'RakuAST::Regex::' ) }
  }

  $node.visit-children( -> $child { validate $child, $text } );

}

# the (...) form of :ver / :auth / :api, evaluated once
my sub selector ( Str:D $text ) {

  my $ast = try $text.AST;

  die X::Pakku::Spec.new: msg => "($text)", comment => 'can not parse selector' ~ ( ": { $!.message.lines.head }" if $! ) without $ast;

  validate $ast, $text;

  EVAL $ast;

}

# the <...> form: Version semantics (1.2 is a prefix, + and * wildcards), auth with * globs
my sub version-matcher ( Str:D $text ) { Version.new: $text.subst( / ^ 'v' <?before \d> /, '' ) }

my sub auth-matcher ( Str:D $text ) {

  return $text unless $text.contains( '*' );

  my $pattern = $text.split( '*' ).map( { "'" ~ .subst( "'", "\\'", :g ) ~ "'" } ).join( ' .*? ' );

  rx/ ^ <$pattern> $ /;

}

# marks a (...) value coming from the grammar
my class CodeText { has Str:D $.text is required }

# Rakudo's own matcher: candidates() smartmatches these, we only stop the base
# class from coercing a selector into a Version
class Pakku::DependencySpecification is CompUnit::DependencySpecification {

  has $.ver-selector;
  has $.auth-selector;
  has $.api-selector;

  method version-matcher { $!ver-selector  // callsame }
  method auth-matcher    { $!auth-selector // callsame }
  method api-matcher     { $!api-selector  // callsame }

}

my role Spec {

  has Str:D $.name  is required;
  has       $.ver;
  has       $.from;
  has       %.hints;

  has Str $.id is built( False );

  method gist ( ) {
    $!name
      ~ ( ":ver<"  ~ $!ver  ~ ">" if defined $!ver  )
      ~ ( ":from<" ~ $!from ~ ">" if defined $!from );
  }

  method Str ( ) { self.gist }

  submethod TWEAK ( ) { $!id = sha1 ~self }

}

class Pakku::Spec::Raku does Spec {

  has $.auth;
  has $.api;

  has Bool $.ver-code  = False;
  has Bool $.auth-code = False;
  has Bool $.api-code  = False;

  has $!ver-matcher;
  has $!auth-matcher;
  has $!api-matcher;

  submethod TWEAK ( ) {

    $!ver-matcher  = $!ver-code  ?? selector( $!ver  ) !! version-matcher( ~$!ver  ) with $!ver;
    $!auth-matcher = $!auth-code ?? selector( $!auth ) !! auth-matcher(    ~$!auth ) with $!auth;
    $!api-matcher  = $!api-code  ?? selector( $!api  ) !! version-matcher( ~$!api  ) with $!api;

    $!id = sha1 ~self;   # a class TWEAK shadows the role's

  }

  method ver-matcher  { $!ver-matcher  }
  method auth-matcher { $!auth-matcher }
  method api-matcher  { $!api-matcher  }

  # for logging and the old-style candidates( $name, |%spec ) call
  method spec ( ) {

    my %h = name => $!name;

    %h<ver>  = $!ver  if defined $!ver;
    %h<auth> = $!auth if defined $!auth;
    %h<api>  = $!api  if defined $!api;
    %h<from> = $!from if defined $!from;

    %h;

  }

  # what Rakudo's repositories match against
  method dependency-specification ( --> CompUnit::DependencySpecification:D ) {

    Pakku::DependencySpecification.new:
      short-name    => $!name,
      ver-selector  => $!ver-matcher,
      auth-selector => $!auth-matcher,
      api-selector  => $!api-matcher;

  }

  method gist ( ) {

    $!name
      ~ ( ( $!ver-code  ?? ":ver($!ver)"   !! ":ver<$!ver>"   ) if defined $!ver  )
      ~ ( ( $!auth-code ?? ":auth($!auth)" !! ":auth<$!auth>" ) if defined $!auth )
      ~ ( ( $!api-code  ?? ":api($!api)"   !! ":api<$!api>"   ) if defined $!api  );

  }

  # does a META (hash) satisfy this spec? name is not compared, so provides can be matched too
  multi method ACCEPTS ( ::?CLASS:D: %h --> Bool:D ) {

    with $!ver-matcher  { return False unless version( %h<ver> // %h<version> ) ~~ $_ }
    with $!auth-matcher { return False unless ( %h<auth> // '' )                ~~ $_ }
    with $!api-matcher  { return False unless version( %h<api> )                ~~ $_ }

    True;

  }

  multi method ACCEPTS ( ::?CLASS:D: Pakku::Spec::Raku:D $spec --> Bool:D ) { samewith $spec.spec }

}

class Pakku::Spec::Bin    does Spec { }
class Pakku::Spec::Native does Spec { }
class Pakku::Spec::Perl   does Spec { }

# S22 alternatives: the first one the recommendation manager can provide wins
class Pakku::Spec::Any {

  has @.spec is required;

  has Str $.id is built( False );

  method name ( ) { 'any(' ~ @!spec.map( *.name ).join( ' | ' ) ~ ')' }
  method gist ( ) { 'any(' ~ @!spec.map( *.gist ).join( ' | ' ) ~ ')' }
  method Str  ( ) { self.gist }

  multi method ACCEPTS ( ::?CLASS:D: $topic --> Bool:D ) { so @!spec.first( -> $spec { $topic ~~ $spec } ) }

  submethod TWEAK ( ) { $!id = sha1 @!spec.map( *.id ).join( ',' ) }

}

grammar SpecGrammar {

  token TOP { <spec> }

  token spec { <name> <pair>* }

  token name { [<-[/:<>()\h]>+]* % '::' }

  token pair { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<api>     { <sym> }
  token key:sym<from>    { <sym> }
  token key:sym<version> { <sym> }

  # Thx to Jo King on SO.
  proto token value { * }
  token value:sym<angles> { '<' ~ '>' $<val>=[ .*? <~~>?] }
  token value:sym<parens> { '(' $<val>=<balanced> ')' }

  token balanced { [ <-[()]> | '(' <balanced> ')' ]* }

}

class SpecActions {

  method TOP ( $/ ) { make $<spec>.made }

  method spec ( $/ ) { make { name => $<name>.Str, $<pair>.map( *.made ) } }

  method pair ( $/ ) { make ( $<key>.made => $<value>.made ) }

  method key:sym<auth>    ( $/ ) { make 'auth' }
  method key:sym<api>     ( $/ ) { make 'api'  }
  method key:sym<from>    ( $/ ) { make 'from' }
  method key:sym<ver>     ( $/ ) { make 'ver'  }
  method key:sym<version> ( $/ ) { make 'ver'  }

  method value:sym<angles> ( $/ ) { make ~$<val> }
  method value:sym<parens> ( $/ ) { make CodeText.new: text => ~$<val> }

}

class Pakku::Spec {

  multi method new ( Str:D $spec ) {

    with SpecGrammar.parse( $spec, actions => SpecActions ).made { self.new: $_ }
    else { die X::Pakku::Spec.new: msg => ~$spec, comment => 'invalid spec!' }

  }

  multi method new ( @spec! ) { Pakku::Spec::Any.new: spec => @spec.map( { self.new: $_ } ).Array }

  multi method new ( %spec! ) {

    return self.new: %spec<any>.List if %spec<any>;

    my %h = %spec;

    # S22 hash form: "name" may itself be a use string with adverbs; explicit keys win
    if %h<name> ~~ Str and %h<name>.contains( ':' ) {

      my %parsed = SpecGrammar.parse( %h<name>, actions => SpecActions ).made
        // die X::Pakku::Spec.new: msg => ~%h<name>, comment => 'invalid spec!';

      %h = |%parsed, |%h.grep( *.key ne 'name' ), name => %parsed<name>;

    }

    die X::Pakku::Spec.new: msg => %h.raku, comment => 'no name!' unless %h<name>;

    %h<ver> //= $_ with %h<version>:delete;

    # (...) values from the grammar become selectors; everything else is a string
    for <ver auth api> -> $key {
      if %h{ $key } ~~ CodeText { %h{ $key } = %h{ $key }.text; %h{ $key ~ '-code' } = True }
    }

    %h<hints> = %( %h<hints> ) if %h<hints>;

    my $from = ( %h<from> // 'raku' ).lc;

    my %attr  = %h.grep( { .key eq any <name ver auth api from hints ver-code auth-code api-code> } );
    my %plain = %attr.grep( { .key eq any <name ver from hints> } );

    given $from {
      when 'raku' | 'perl6' { Pakku::Spec::Raku.new:   |%attr  }
      when 'bin'            { Pakku::Spec::Bin.new:    |%plain }
      when 'native'         { Pakku::Spec::Native.new: |%plain }
      when 'perl5'          { Pakku::Spec::Perl.new:   |%plain }
      default               { die X::Pakku::Spec.new: msg => ~%h<name>, comment => "unknown from<$from>!" }
    }

  }

  multi method new ( IO::Path:D $path! ) {

    my $meta-file = meta-file $path;

    die X::Pakku::Spec.new: msg => ~$path, comment => 'no META6.json!' unless $meta-file;

    my %meta = Rakudo::Internals::JSON.from-json: $meta-file.slurp;

    samewith %meta<name ver version auth api>:p.grep( *.value.defined ).Hash;

  }

}
