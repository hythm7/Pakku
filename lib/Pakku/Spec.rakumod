use X::Pakku;

unit class Pakku::Spec;

has $.name      is required;
has $.ver;
has $.version;
has $.auth;
has $.api;
has $.from;
has $.prefix;


method spec ( ) {

  my %h;

  %h<name>    = $!name;
  %h<ver>     = $!ver   if defined $!ver;
  %h<auth>    = $!auth  if defined $!auth;
  %h<api>     = $!api   if defined $!api;
  %h<from>    = $!from  if defined $!from;

  %h;
}

method gist ( ) {

  $!name
    ~ ( ":ver<"  ~ $!ver  ~ ">" if defined $!ver  )
    ~ ( ":auth<" ~ $!auth ~ ">" if defined $!auth )
    ~ ( ":api<"  ~ $!api  ~ ">" if defined $!api  )
    ~ ( ":from<" ~ $!from ~ ">" if defined $!from and $!from ne 'raku'    );

}

method Str ( ) { self.gist }

multi method ACCEPTS ( ::?CLASS:D: %h --> Bool:D ) {

  # disable match by name to allow match for %provides
  # do return False unless %h<name> ~~ $!name;
  do return False unless Version.new( %h<ver> // %h<version> ) ~~ Version.new( $!ver )  if defined $!ver;
  do return False unless %h<auth> ~~ $!auth if defined $!auth;
  do return False unless %h<api>  ~~ $!api  if defined $!api;
  #do return False unless %h<from> ~~ $!from if defined $!from;

  True;

}

multi method ACCEPTS ( ::?CLASS:D: Pakku::Spec:D $spec! --> Bool:D ) {

  samewith $spec.spec;

}

multi sub infix:<cmp>( Pakku::Spec:D \a, Pakku::Spec:D \b --> Order:D ) is export {

  ( Version.new( a.ver ) cmp Version.new( b.ver ) ) or quietly
  ( Version.new( a.api ) cmp Version.new( b.api ) );

}

grammar SpecGrammar {

  token TOP { <spec> }

  token spec { <name> <pair>* }

  token name { [<-[/:<>()\h]>+]+ % '::' }

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
  token value:sym<parens> { '(' ~ ')' $<val>=[ .*? <~~>?] }


}

class SpecActions {

  method TOP ( $/ ) { make $<spec>.made }

  # TODO Make it work with Regex matchers
  method spec ( $/ ) {

    make  { name => $/<name>.Str, $/<pair>.map( *.made ) };
  }

  method pair ( $/ ) { make ( $<key>.made => $<value>.made ) }

  method key:sym<auth>    ( $/ ) { make 'auth' }
  method key:sym<api>     ( $/ ) { make 'api' }
  method key:sym<from>    ( $/ ) { make 'from' }
  method key:sym<ver>     ( $/ ) { make 'ver' }
  method key:sym<version> ( $/ ) { make 'ver' }

  method value:sym<angles> ( $/ )  { make ~$<val> }
  method value:sym<parens> ( $/ )  { make ~$<val> }

}


submethod TWEAK ( ) {

  $!ver //= $!version;
  $!from //= 'raku';

}

multi method new ( Str:D $spec ) {

  with Pakku::Spec::SpecGrammar.parse( $spec, actions => Pakku::Spec::SpecActions ).made {

    self.bless: |$_;

  } else { die X::Pakku::Spec.new: :$spec }

}

multi method new ( @spec! ) {

  @spec.map( -> $spec { self.new: $spec } );

}


multi method new ( IO $prefix! ) {

  my @meta = <META6.json META6.info META.json META.info>;

  my $meta-file = @meta.map( -> $file { $prefix.add: $file } ).first( *.f );


  die X::Pakku::Spec.new: spec => $prefix unless $meta-file;

  my %meta = Rakudo::Internals::JSON.from-json: $meta-file.slurp;

  %meta<ver> //= %meta<version>;

  self.new: %meta<name ver auth api>:kv .hash .append: ( :$prefix );

}

multi method new ( %spec! ) {

  return self.new: %spec<any> if %spec<any>;

  self.bless: |%spec;

}

subset Pakku::Spec::Raku   of Pakku::Spec where .from ~~ 'raku';
subset Pakku::Spec::Perl   of Pakku::Spec where .from ~~ 'perl';
subset Pakku::Spec::Bin    of Pakku::Spec where .from ~~ 'bin';
subset Pakku::Spec::Native of Pakku::Spec where .from ~~ 'native';

