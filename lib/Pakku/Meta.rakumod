use Terminal::ANSIColor;

use X::Pakku::Meta;
use Pakku::Spec;

unit class Pakku::Meta;

my class Identity {

  has Str     $.auth;
  has Str     $.name;
  has Version $.ver; 

  submethod BUILD ( :$!auth!, :$name!, :$!ver! ) {

    $!name = $name.subst: '::', '-', :g;

  }

  method Str ( ) {

    quietly ( $!auth, $!name, $!ver ).join( ':' )

  }

}


has %.meta;

has Version $.meta-version;
has Version $!perl;
has Version $.version;
has Version $!ver;
has Version $.api;

has Str     $.name;
has Str     $.auth;
has Str     $.description;
has Str     $.author;
has Str     $.license;
has Str     $.source-url;
has Str     $.builder;

has Bool    $.production;

has $.authors;
has $.build-depends;
has $.test-depends;
has $.resources;
has $.tags;
has $.path;
has $.recman-src;


has %.provides;
has $.depends;
has %.build;

has %.emulates;
has %.supersedes;
has %.superseded-by;
has %.excludes;
has %.support;

has %!deps;

has Identity $!identity;


method ver ( ) { $!version }

method raku-version  ( ) {  $!perl }
method to-json  ( ) { Rakudo::Internals::JSON.to-json: %!meta }

method identity ( ) { $!identity }

multi method Str ( ::?CLASS:D: --> Str:D ) {

  quietly "{$!name}:ver<$!ver>:auth<$!auth>:api<$!api>"

}


multi method deps ( ) { %!deps }

multi method deps ( Bool:D :$deps where *.so ) {

  samewith :deps<suggests>;

}

multi method deps ( Str:D :$deps where 'suggests' ) {

  %!deps<build test runtime>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'only' ) {

  samewith :deps;

}


multi method deps ( Str:D :$deps where 'recommends' ) {

  %!deps<build test runtime>.map( *<requires recommends>.grep( *.defined ).Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'requires' ) {

  %!deps<build test runtime>.map( *<requires>.grep( *.defined ).Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'runtime' ) {

  %!deps<runtime>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'test' ) {

  %!deps<test>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'build' ) {

  %!deps<build>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Bool:D :$deps where not *.so ) {

  Empty;

}


method to-dist ( ::?CLASS:D: IO :$prefix! ) {

  # %bins and resources stolen from Rakudo
  my %bins = Rakudo::Internals.DIR-RECURSE($prefix.add('bin').absolute).map(*.IO).map: -> $real-path {
    my $name-path = $real-path.is-relative
      ?? $real-path
      !! $real-path.relative($prefix);
    $name-path.subst(:g, '\\', '/') => $name-path.subst(:g, '\\', '/')
  }

  my $resources-dir = $prefix.add('resources');
  my %resources = self.resources.grep(*.?chars).map(*.IO).map: -> $path {
    my $real-path = $path ~~ m/^libraries\/(.*)/
        ?? $resources-dir.add('libraries').add( $*VM.platform-library-name($0.Str.IO) )
        !! $resources-dir.add($path);
    my $name-path = $path.is-relative
        ?? "resources/{$path}"
        !! "resources/{$path.relative($prefix)}";
    $name-path.subst(:g, '\\', '/') => $real-path.relative($prefix).subst(:g, '\\', '/')
  }

  %!meta<files> = Hash.new(%bins, %resources);

  self does Distribution::Locally( :$prefix );

}


submethod TWEAK ( ) {

  $!identity = Identity.new: auth => self.auth, name => self.name, ver => self.ver;

  $!ver = $!version;

  %!deps<build><requires>.append: flat self.build-depends if self.build-depends;
  %!deps<test><requires>.append:  flat self.test-depends  if self.test-depends;

  given self.depends {

    when Positional {

      %!deps<runtime><requires>.append: flat self.depends if self.depends;

    }

    when Associative {

      %!deps<runtime><requires>.append:   flat .<runtime>             if .<runtime> ~~ Positional;
      %!deps<test><requires>.append:      flat .<test>                if .<test>    ~~ Positional;
      %!deps<build><requires>.append:     flat .<build>               if .<build>   ~~ Positional;

      %!deps<runtime><requires>.append:   flat  .<runtime><requires>  if .<runtime><requires>;
      %!deps<runtime><recommends>.append: flat .<runtime><recommends> if .<runtime><recommends>;
      %!deps<runtime><suggests>.append:   flat  .<runtime><suggests>  if .<runtime><suggests>;

      %!deps<test><requires>.append:      flat   .<test><requires>    if .<test><requires>;
      %!deps<test><recommends>.append:    flat   .<test><recommends>  if .<test><recommends>;
      %!deps<test><suggests>.append:      flat   .<test><suggests>    if .<test><suggests>;

      %!deps<build><requires>.append:     flat   .<build><requires>   if .<build><requires>;
      %!deps<build><recommends>.append:   flat   .<build><recommends> if .<build><recommends>;
      %!deps<build><suggests>.append:     flat   .<build><suggests>   if .<build><suggests>;
    }

  }


}

proto method new ( | ) { * };

multi method new ( Str:D $json ) {

  my $meta = Rakudo::Internals::JSON.from-json: $json;

  die X::Pakku::Meta.new: meta => $json unless $meta;

  samewith $meta;

}

multi method new ( IO::Path:D $path ) {

  my @meta = <META6.json META6.info META.json META.info>;

  my $meta-file = @meta.map( -> $file { $path.add: $file } ).first( *.f );

  die X::Pakku::Meta.new: meta => $path unless $meta-file;

  my $meta = Rakudo::Internals::JSON.from-json: $meta-file.slurp;

  $meta<path> = $path;

  samewith $meta;

}

multi method new ( %meta ) {

  die X::Pakku::Meta.new: :%meta unless %meta<name>;

  %meta<meta-version> = Version.new( %meta<meta-version> || 0   );
  %meta<perl>         = Version.new( %meta<perl>         || '*' );
  %meta<version>      = Version.new( %meta<version> // %meta<ver> // ''   );
  %meta<api>          = Version.new( %meta<api>          // ''  );

  %meta<auth> //= %meta<authors>.head // '';

  %meta<production> .= so if defined %meta<production>;

  %meta{ grep { not defined %meta{ $_ } }, %meta.keys}:delete;

  self.bless: :%meta, |%meta;
}


multi method gist ( ::?CLASS:D: Bool:D :$details --> Str:D ) {

  return colored( ~self, '177' ) unless $details;
  
  (
    ( colored( ~self, '177' )                  ),
    ( gist-name $!name                         ),
    ( gist-ver  $!ver         if $!ver         ),
    ( gist-auth $!auth        if $!auth        ),
    ( gist-api  $!api         if $!api         ),
    ( gist-desc $!description if $!description ),
    ( gist-url  $!source-url  if $!source-url  ),
    ( gist-deps %!deps        if %!deps        ),
    ( gist-prov %!provides    if %!provides    ),
    (            ''                            ),
  ).join( "\n" );


}

sub gist-name ( $name --> Str:D ) {

  colored( 'name', '33'     ) ~
  colored( ' → ',  'yellow' ) ~
  colored( ~$name, '117'    )

}

sub gist-ver ( $ver --> Str:D ) {

  colored( 'ver',  '33'     ) ~
  colored( '  → ', 'yellow' ) ~
  colored( ~$ver,  '117'    )

}

sub gist-auth ( $auth --> Str:D ) {

  colored( 'auth', '33'     ) ~
  colored( ' → ',  'yellow' ) ~
  colored( ~$auth, '117'    )

}

sub gist-api ( $api --> Str:D ) {

  colored( 'api',  '33'     ) ~
  colored( '  → ', 'yellow' ) ~
  colored( ~$api,  '117'    )

}

sub gist-desc ( $desc --> Str:D ) {

  colored( 'desc', '33'     ) ~
  colored( ' → ',  'yellow' ) ~
  colored( ~$desc, '117'    )

}

sub gist-url ( $url --> Str:D ) {

  colored( 'url',  '33'     ) ~
  colored( '  → ', 'yellow' ) ~
  colored( ~$url,  '117'    )

}

sub gist-deps ( %deps --> Str:D ) {

  my $label = colored( 'deps', '33' );
  (
      "$label \n" ~
       %deps.kv.map( -> $phase, $need {
         colored( '↳ ',  'yellow'    )           ~
         colored( ~$phase, '68' ) ~ "\n"         ~
         colored( '↳ ',  'yellow'    ).indent(2) ~
         colored( ~$need.keys, '66' ) ~ "\n"     ~
            $need.values.map( -> @spec  {
                @spec.map( -> $spec {
                  colored( '↳ ',  'yellow'    )  ~
                  colored( $spec.gist,  '177' )
                } ).join("\n").indent( 4 )

               } )
       }).join( "\n" ).indent( 5 )
  )

}

sub gist-prov ( %prov --> Str:D ) {

  my $label = colored( 'prov', '33' );

  (
    "$label \n" ~
     %prov.kv.map( -> $unit, $file {
       $file ~~ Hash
         ?? colored( '↳ ',  'yellow'    )                      ~
            colored( ~$unit, '177' ) ~ "\n"                    ~
            colored( '↳ ',  'yellow'    ).indent( 2 )          ~
            colored( ~$file.keys, '66' )  ~ "\n"               ~
              $file.kv.map( -> $file, $info {
                $info.grep( *.value ).hash.kv.map( -> $k, $v {
                  colored( '↳ ',  'yellow'       ).indent( 2 ) ~
                  colored( ~$k, '70'    )                      ~
                  colored( ' → ',  'yellow'      )             ~
                  colored( ~$v, '117' )
                } ).join("\n").indent( 2 )
              })
         !! colored( '↳ ', 'yellow'  )                         ~
            colored( ~$unit, '177' ) ~ "\n"                    ~
            colored( '↳ ',  'yellow'    ).indent( 2 )          ~
            colored( $file, '66'    );
     }).join( "\n" ).indent( 5 )
  )
}

