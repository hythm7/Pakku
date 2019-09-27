unit class Pakku::Spec;
  also is CompUnit::DependencySpecification;


grammar SpecGrammar {

  token TOP { <spec> }

  token spec { <name> <keyval>* }

  token name { [<-[./:<>()\h]>+]+ % '::' }

  token keyval { ':' <key> <value> }

  proto token key { * }
  token key:sym<ver>     { <sym> }
  token key:sym<version> { <sym> }
  token key:sym<auth>    { <sym> }
  token key:sym<api>     { <sym> }
  token key:sym<from>    { <sym> }

  # BUG: fix specs that have '<>' inside value;
  token value { '<' ~ '>' $<val>=<-[<>]>* | '(' ~ ')' $<val>=<-[()]>* }

}

class SpecActions {

  method TOP ( $/ ) { make $<spec>.ast }

  method spec ( $/ ) {
    my %id;

    %id<name> = $<name>.Str;
    %id.push: ( $<keyval>».ast ) if $<keyval>;

    my %spec;

    %spec<short-name>      = %id<name> if %id<name>;
    %spec<from>            = %id<from> if %id<from>;
    %spec<version-matcher> = %id<ver>  if %id<ver>;
    %spec<auth-matcher>    = %id<auth> if %id<auth>;
    %spec<api-matcher>     = %id<api>  if %id<api>;

    make %spec;

  }

  method keyval ( $/ ) { make ( $<key>.Str => $<value>.ast ) }

  method value ( $/ )  { make $<val>.Str }

}


method new ( Str :$spec ) {

  my $grammar = SpecGrammar;
  my $actions = SpecActions;

  my $m = $grammar.parse( $spec, :$actions );

  die "I don't understand this spec: [$spec]" unless $m;

  my %spec = $m.ast;

  self.bless: |%spec;

}

method name ( ) {

  $.short-name

}

method version ( ) {

  return Version.new  if $.version-matcher ~~ Bool;

  Version.new: $.version-matcher;
}

method auth ( ) {

  return Any if $.auth-matcher ~~ Bool;

  $.auth-matcher;

}

method api ( ) {

  return Any if $.api-matcher ~~ Bool;

  $.api-matcher;

}


# no type checking to avoid circular dependency
multi method ACCEPTS ( Pakku::Spec:D: $dist --> Bool:D ) {

  return False unless $.name ~~ any( $dist.name, $dist.provides );
  return False unless Version.new( $dist.version ) ~~ $.version;
  return False unless $dist.auth ~~ $.auth;
  return False unless $dist.api  ~~ $.api-matcher;

  True;

}


