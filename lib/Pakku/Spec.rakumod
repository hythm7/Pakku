use experimental :rakuast;
use MONKEY-SEE-NO-EVAL;

use X::Pakku;
use Pakku::Util;

# Dependency specifications, with Raku's own semantics (S11, S22):
#   Foo:ver<1.2+>:auth<zef:x>:api<1>   <...> is a string: Version / auth rules of Rakudo
#   Foo:ver(* > 0.2):auth(/^zef/)      (...) is code: any smartmatch selector
#   { "name": "Foo", "ver": "1.2+" }   hash form, name may carry adverbs
#   { "any": [ ... ] }                 alternatives, recursive
# Selectors are parsed with Rakudo's own parser (RakuAST) and evaluated by Raku;
# matching is plain ~~. They must be data (literals, versions, ranges, junctions,
# regexes, Whatever code, Any), never code that runs (blocks, calls, variables):
# a spec also comes from other people's META files and the ecosystem index.

# inside :ver( ) and :api( ) a bare number is a version: * > 0.2 is * > v0.2
# (the literals are found through Rakudo's parse, so "1.2" and /2/ are left alone)
my sub versionise ( Str:D $text, $ast --> Str:D ) {

  my @at;

  my sub walk ( $node ) {
    if $node ~~ RakuAST::IntLiteral | RakuAST::RatLiteral | RakuAST::NumLiteral {
      with $node.origin { @at.push: .from if $text.substr( .from, .to - .from ) ~~ / ^ \d+ [ '.' \d+ ]* $ / }
    }
    $node.visit-children( &walk );
  }

  walk $ast;

  my $code = $text;

  $code.substr-rw( $_, 0 ) = 'v' for @at.sort.reverse;   # from the end, so the offsets stay right

  $code;

}

my constant @INFIX  = '..', '..^', '^..', '^..^', '<', '<=', '>', '>=', '==', '!=', '===', 'eqv', '~~',
                      'eq', 'ne', 'lt', 'le', 'gt', 'ge', 'before', 'after',
                      '|', '&', '^', '&&', '||', '^^', '//', 'and', 'or', 'xor';
my constant @PREFIX = '!', 'not', 'so';

# a regex is data too, as long as it carries no code: no { }, <{ }>, <?{ }>, <&f>, $vars, <~~>
my constant @REGEX-CODE = <Block Interpolation Assertion::InterpolatedBlock Assertion::PredicateBlock
                           Assertion::Callable Assertion::InterpolatedVar Assertion::Recurse>;
my constant @RULES = <alpha alnum digit xdigit space blank upper lower punct cntrl graph print ident ws wb ww same before after>;

my constant @CURRYING = '|', '&', '^', '&&', '||', '^^', '//', 'and', 'or', 'xor';

my sub has-whatever ( $node --> Bool:D ) {
  my $found = False;
  my sub walk ( $n ) { $found = True if $n ~~ RakuAST::Term::Whatever | RakuAST::WhateverCode::Argument; $n.visit-children( &walk ) unless $found }
  walk $node;
  $found;
}

my sub validate ( $node, Str:D $text --> Nil ) {

  my sub refuse ( Str $why ) { die X::Pakku::Spec.new: msg => "($text)", comment => "$why: not a version/auth/api selector" }

  # (* > 1) & (* < 2) is not two selectors joined: Raku curries both stars into one code that takes two
  # values; v1 | (* > 2) curries into a code that returns a junction, true for every version
  my sub refuse-curry ( $infix, *@operand ) {
    refuse "star code joined with { $infix.operator } (Raku curries it into one code: write all(* > 1, * < 2), any(...), none(...) or a range)"
      if $infix ~~ RakuAST::Infix and $infix.operator eq any @CURRYING and @operand.first( &has-whatever );
  }

  given $node {
    when RakuAST::StatementList                 { refuse 'more than one statement' unless .statements == 1 }
    when RakuAST::Statement::Expression         { }
    when RakuAST::ApplyInfix                    { refuse-curry .infix, .left, .right }
    when RakuAST::ApplyListInfix                { refuse-curry .infix, |.operands }
    when RakuAST::Infix                         { refuse "operator { .operator }" unless .operator eq any @INFIX }
    when RakuAST::ApplyPrefix                   { }
    when RakuAST::Prefix                        { refuse "operator { .operator }" unless .operator eq any @PREFIX }
    when RakuAST::ArgList                       { }
    when RakuAST::WhateverCode::Argument        { }
    when RakuAST::Term::Whatever                { }
    when RakuAST::VersionLiteral                { }
    when RakuAST::IntLiteral                    { }
    when RakuAST::RatLiteral                    { }
    when RakuAST::NumLiteral                    { }
    when RakuAST::StrLiteral                    { }
    when RakuAST::QuotedString                  { refuse 'a quoted string that runs a command' if .processors.grep( 'exec' ); refuse "quote processor { .processors.join( ':' ) }" if .processors.grep( * ne any <words val quotewords> ) }
    when RakuAST::QuotedRegex                   { }
    when RakuAST::Circumfix::Parentheses        { }
    when RakuAST::SemiList                      { }
    when RakuAST::Type::Simple                  { refuse "type { .name.canonicalize }" unless .name.canonicalize eq 'Any' }
    when RakuAST::Call::Name                    { refuse "call to { .name.canonicalize }" unless .name.canonicalize eq any <any all one none> }
    when RakuAST::Name                          { }
    when RakuAST::Regex::Assertion::Named       { refuse "<{ .name.canonicalize }> in a regex" unless .name.canonicalize eq any @RULES }
    when RakuAST::Regex::QuantifiedAtom         { refuse 'a quantified group in a regex (it can backtrack forever)' if .atom ~~ RakuAST::Regex::Group | RakuAST::Regex::CapturingGroup | RakuAST::Regex::NamedCapture }
    default                                     {
      my $kind = .^name.subst( 'RakuAST::', '' );
      refuse $kind unless $kind.starts-with( 'Regex::' );
      refuse "code inside a regex ({ $kind.subst( 'Regex::', '' ) })" if $kind.subst( 'Regex::', '' ) eq any @REGEX-CODE;
    }
  }

  $node.visit-children( -> $child { validate $child, $text } );

}

# the (...) form of :ver / :auth / :api, evaluated once
# any smartmatch selector that is data, not code: Raku parses it, Raku evaluates it
my sub selector ( Str:D $text, Bool:D :$versions = False ) {

  # 1.2.3 is not a Raku literal, v1.2.3 is: be nice to version numbers (outside quotes and regexes)
  my $code = $versions ?? $text.subst( / <!after <[\w.'"/]>> ( \d+ [ '.' \d+ ] ** 2..* ) <!before <[\w.'"/]>> /, { "v$0" }, :g ) !! $text;

  my $ast = try $code.AST;

  die X::Pakku::Spec.new: msg => "($text)", comment => 'can not parse selector' ~ ( ": { $!.message.lines.head }" if $! ) without $ast;

  validate $ast, $text;

  if $versions {

    my $versioned = versionise $code, $ast;

    $ast = $versioned.AST unless $versioned eq $code;

    validate $ast, $text;

  }

  my $selector = EVAL $ast;

  # 1 < * < * is one code with two stars: it can never match one version (.WHAT does not autothread a junction)
  die X::Pakku::Spec.new: msg => "($text)", comment => "a selector takes one value, this one takes { $selector.arity } (write all(* > 1, * < 2), any(...) or a range)"
    if $selector.WHAT ~~ Code and $selector.arity > 1;

  $selector;

}

# the <...> form: Version semantics (1.2 is a prefix, + and * wildcards), auth with * globs
my sub version-matcher ( Str:D $text ) { Version.new: $text }   # v2.0 is not 2.0 for Rakudo either: the v is a part

my sub auth-matcher ( Str:D $text ) {

  return $text unless $text.contains( '*' );

  my $pattern = $text.split( '*' ).map( { "'" ~ .subst( "'", "\\'", :g ) ~ "'" } ).join( ' .*? ' );

  rx/ ^ <$pattern> $ /;

}

# marks a (...) value coming from the grammar
my class CodeText { has Str:D $.text is required }

# Rakudo's own matcher: candidates() smartmatches these, we only stop the base
# class from coercing a selector into a Version
# is there a matcher? `with` and `//` would ask a junction, which answers with a junction (none(v1) is "false"
# when asked if it is defined); .WHAT does not autothread. An Any selector means no constraint, like no matcher.
my sub present ( Mu $matcher --> Bool:D ) { not $matcher.WHAT =:= Any }   # Mu: a junction argument must not autothread the call

class Pakku::DependencySpecification is CompUnit::DependencySpecification {

  has $.ver-selector;
  has $.auth-selector;
  has $.api-selector;

  method version-matcher { present( $!ver-selector  ) ?? $!ver-selector  !! callsame }
  method auth-matcher    { present( $!auth-selector ) ?? $!auth-selector !! callsame }
  method api-matcher     { present( $!api-selector  ) ?? $!api-selector  !! callsame }

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

    $!ver-matcher  = $!ver-code  ?? selector( $!ver, :versions ) !! version-matcher( ~$!ver ) with $!ver;
    $!auth-matcher = $!auth-code ?? selector( $!auth ) !! auth-matcher(    ~$!auth ) with $!auth;
    $!api-matcher  = $!api-code  ?? selector( $!api, :versions ) !! version-matcher( ~$!api ) with $!api;

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

    # a selector that dies on a value (1e3 against a version, say) simply does not match it
    if present $!ver-matcher  { return False unless try version( %h<ver> // %h<version> ) ~~ $!ver-matcher  }
    if present $!auth-matcher { return False unless try ( %h<auth> // '' )                ~~ $!auth-matcher }
    if present $!api-matcher  { return False unless try version( %h<api> )                ~~ $!api-matcher  }

    True;

  }

  multi method ACCEPTS ( ::?CLASS:D: Pakku::Spec::Raku:D $spec --> Bool:D ) { samewith $spec.spec }

}

class Pakku::Spec::Bin    does Spec { }
class Pakku::Spec::Native does Spec { }
class Pakku::Spec::Perl   does Spec { }

# S22 alternatives: the first one the recommendation manager can provide wins
# alternatives: one of them (S22 "any")
class Pakku::Spec::Any {

  has @.spec is required;

  has Str $.id is built( False );

  method name ( ) { 'any(' ~ @!spec.map( *.name ).join( ' | ' ) ~ ')' }
  method gist ( ) { 'any(' ~ @!spec.map( *.gist ).join( ' | ' ) ~ ')' }
  method Str  ( ) { self.gist }

  multi method ACCEPTS ( ::?CLASS:D: $topic --> Bool:D ) { so @!spec.first( -> $spec { $topic ~~ $spec } ) }

  submethod TWEAK ( ) { $!id = sha1 @!spec.map( *.id ).join( ',' ) }

}

# a group: all of them (S22: a list inside the alternatives, or inside depends, is a list of dependencies)
class Pakku::Spec::All {

  has @.spec is required;

  has Str $.id is built( False );

  method name ( ) { 'all(' ~ @!spec.map( *.name ).join( ' & ' ) ~ ')' }
  method gist ( ) { 'all(' ~ @!spec.map( *.gist ).join( ' & ' ) ~ ')' }
  method Str  ( ) { self.gist }

  multi method ACCEPTS ( ::?CLASS:D: $topic --> Bool:D ) { not @!spec.first( -> $spec { not $topic ~~ $spec } ) }

  submethod TWEAK ( ) { $!id = sha1 'all:' ~ @!spec.map( *.id ).join( ',' ) }

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

  proto token value { * }
  token value:sym<angles> { '<' $<val>=<angled>   '>' }
  token value:sym<parens> { '(' $<val>=<balanced> ')' }

  token angled   { [ <-[<>]> | '<' <angled>   '>' ]* }
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

  multi method new ( @spec! ) { Pakku::Spec::All.new: spec => @spec.map( { self.new: $_ } ).Array }

  multi method new ( %spec! ) {

    return Pakku::Spec::Any.new: spec => %spec<any>.List.map( { self.new: $_ } ).Array if %spec<any>;

    my %h = %spec;

    %h<ver> //= $_ with %h<version>:delete;   # version and ver are the same key, before the adverbs of name are merged

    # S22 hash form: "name" may itself be a use string with adverbs; explicit keys win
    if %h<name> ~~ Str and %h<name>.contains( ':' ) {

      my %parsed = SpecGrammar.parse( %h<name>, actions => SpecActions ).made
        // die X::Pakku::Spec.new: msg => ~%h<name>, comment => 'invalid spec!';

      %h = |%parsed, |%h.grep( *.key ne 'name' ), name => %parsed<name>;

    }

    die X::Pakku::Spec.new: msg => %h.raku, comment => 'no name!' unless %h<name>;

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
