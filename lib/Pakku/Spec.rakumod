use X::Pakku;

my role Spec {

  has $.name is required;
  has $.ver;
  has $.from;

  has Str $.id is built( False );

  method gist ( ) {
    $!name
      ~ ( ":ver<"  ~ $!ver  ~ ">" if defined $!ver  )
      ~ ( ":from<" ~ $!from ~ ">" if defined $!from );
  }

  method Str ( ) { self.gist }

  submethod TWEAK ( ) { use nqp; $!id = nqp::sha1( ~self ) }
}

class Pakku::Spec::Raku does Spec {

has $.auth;
has $.api;


method spec ( ) {

  my %h;

  %h<name>    = $!name;
  %h<ver>     = $!ver   if $!ver;
  %h<auth>    = $!auth  if $!auth;
  %h<api>     = $!api   if $!api;
  %h<from>    = $!from  if $!from;

  %h;
}

method gist ( ) {

  $!name
    ~ ( ":ver<"  ~ $!ver  ~ ">" if defined $!ver  )
    ~ ( ":auth<" ~ $!auth ~ ">" if defined $!auth )
    ~ ( ":api<"  ~ $!api  ~ ">" if defined $!api  );

}


multi method ACCEPTS ( ::?CLASS:D: %h --> Bool:D ) {

  # disable match by name to allow match for %provides
  # do return False unless %h<name> ~~ $!name;
  do return False unless Version.new( %h<ver> // %h<version> ) ~~ Version.new( $!ver )  if $!ver;
  do return False unless %h<auth> ~~ $!auth if $!auth;
  do return False unless %h<api>  ~~ $!api  if $!api;
# do return False unless %h<from> ~~ $!from if $!from;

  True;

}

multi method ACCEPTS ( ::?CLASS:D: Pakku::Spec::Raku:D $meta! --> Bool:D ) {
  samewith $meta.spec;

}

multi sub infix:<cmp>( Pakku::Spec::Raku:D \a, Pakku::Spec::Raku:D \b --> Order:D ) is export {

  ( Version.new( a.ver ) cmp Version.new( b.ver ) ) or quietly
  ( Version.new( a.api ) cmp Version.new( b.api ) );

}


}

class Pakku::Spec::Bin    does Spec { }
class Pakku::Spec::Native does Spec { }
class Pakku::Spec::Perl   does Spec { }

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

class Pakku::Spec {

  multi method new ( Str:D $spec ) {

    with SpecGrammar.parse( $spec, actions => SpecActions ).made {

      self.new: $_;

    } else { die X::Pakku::Spec.new: :$spec }

  }

  multi method new ( @spec! ) {
    @spec.map( -> $spec { self.new: $spec } );
  }


  multi method new ( %spec! ) {

    return self.new: %spec<any> if %spec<any>;

    my $from = %spec<from> // 'raku';

    given $from.lc {
      when 'raku'   { Pakku::Spec::Raku.new:   |%spec }
      when 'bin'    { Pakku::Spec::Bin.new:    |%spec }
      when 'native' { Pakku::Spec::Native.new: |%spec }
      when 'perl5'  { Pakku::Spec::Perl.new:   |%spec }
    }
  }

  multi method new ( IO::Path:D $path! ) {

    my @meta = <META6.json META6.info META.json META.info>;

    my $meta-file = @meta.map( -> $file { $path.add: $file } ).first( *.f );


    die X::Pakku::Spec.new: spec => $path unless $meta-file;

    my %meta = Rakudo::Internals::JSON.from-json: $meta-file.slurp;

    %meta<ver> //= %meta<version>;

    samewith %meta;

  }


}

