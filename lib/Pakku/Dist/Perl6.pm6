use Terminal::ANSIColor;
use Pakku::Dist;
use Pakku::DepSpec;
use Distribution::Builder::MakeFromJSON;

unit class Pakku::Dist::Perl6;
  also is Pakku::Dist;

has $.meta;

# This long list of attributes were copied
# from `Zef` The perl6 module manager
# because I'm lazy to write them all
#
has $.meta-version;
has $.name;
has $.auth;
has $.author;
has $.authority;
has $.api;
has $.ver;
has $.description;
has %.provides;
has $.source-url;
has $.license;
has @.build-depends;
has @.test-depends;
has %.depends;
has @.resources;
has %.support;
has $.builder;
has %!emulates;
has %!superseded-by;
has %!excludes;


method Str ( Pakku::Dist::Perl6:D: --> Str:D ) {

  $!name ~ ":ver<$!ver>:auth<$!auth>:api<$!api>"

}

method deps (

  Pakku::Dist::Perl6:D:

  Bool:D :$runtime    = True,
  Bool:D :$test       = True,
  Bool:D :$build      = True,
  Bool:D :$requires   = True,
  Bool:D :$recommends = True,

) {

  my @deps = flat gather {

    if $build {

      %!depends<build><requires>   .grep( *.defined ).map( *.take ) if $requires;
      %!depends<build><recommends> .grep( *.defined ).map( *.take ) if $recommends;

    }

    if $test {

      %!depends<test><requires>   .grep( *.defined ).map( *.take ) if $requires;
      %!depends<test><recommends> .grep( *.defined ).map( *.take ) if $recommends;

    }

    if $runtime {

      %!depends<runtime><requires>   .grep( *.defined ).map( *.take ) if $requires;
      %!depends<runtime><recommends> .grep( *.defined ).map( *.take ) if $recommends;

    }
  }

}

multi method gist ( Pakku::Dist::Perl6:D: :$details where not *.so --> Str:D ) {

  colored( ~self, "bold cyan" );

}

multi method gist ( Pakku::Dist::Perl6:D: :$details where *.so --> Str:D ) {

  (
    (           self.gist     ),
    ( gist-name $!name        ),
    ( gist-ver  $!ver         ),
    ( gist-auth $!auth        ),
    ( gist-api  $!api         ),
    ( gist-desc $!description ),
    ( gist-bldr $!builder     ),
    ( gist-url  $!source-url  ),
    ( gist-deps self.deps     ),
    ( gist-prov %!provides    ),
    (           ''            ),
  ).join( "\n" );
}

sub gist-name ( $name ) {

  colored( 'name', 'bold green' ) ~
  colored( ' → ',  'yellow'     ) ~
  colored( ~$name, 'bold cyan'  )
  if $name

}

sub gist-ver ( $ver ) {

  colored( 'ver',  'bold green' ) ~
  colored( '  → ', 'yellow'     ) ~
  colored( ~$ver,  'bold cyan'  )
  if $ver

}

sub gist-auth ( $auth ) {

  colored( 'auth', 'bold green' ) ~
  colored( ' → ',  'yellow'     ) ~
  colored( ~$auth, 'bold cyan'  )
  if $auth

}

sub gist-api ( $api ) {

  colored( 'api',  'bold green' ) ~
  colored( '  → ', 'yellow'     ) ~
  colored( ~$api,  'bold cyan'  )
  if $api

}

sub gist-desc ( $desc ) {

  colored( 'desc', 'bold green' ) ~
  colored( ' → ',  'yellow'     ) ~
  colored( ~$desc, 'bold cyan'  )
  if $desc

}

sub gist-url ( $url ) {

  colored( 'url',  'bold green' ) ~
  colored( '  → ', 'yellow'     ) ~
  colored( ~$url,  'bold cyan'  )
  if $url

}

sub gist-bldr ( $bldr ) {

  colored( 'url', 'bold green' ) ~
  colored( ' → ', 'yellow'     ) ~
  colored( ~( $bldr // $bldr.^name ), 'bold cyan' )
  if $bldr

}


sub gist-deps ( @deps ) {

  my $label = colored( 'deps', 'bold green');

  (
     "$label\n" ~
      @deps.map( -> $dep {
        colored( '↳ ', 'yellow' ) ~ colored( ~$dep, 'bold cyan' )
      } ).join("\n").indent( 5 )
  ) if @deps;
}

sub gist-prov ( %prov --> Str:D ) {

  my $label = colored( 'prov', 'bold green' );

  (
    "$label \n" ~
     %prov.kv.map( -> $mod, $path {
       $path ~~ Hash
         ?? colored( '↳ ',  'yellow'    ) ~
            colored( $mod, 'bold green' ) ~
            colored( ' → ', 'yellow'    ) ~
            colored( ~$path.keys, 'bold cyan' ) ~ "\n" ~
               $path.kv.map( -> $path, $info {
                  $info.kv.map( -> $k, $v {
                   colored( '↳ ',  'yellow'       ) ~
                   colored( $k, 'bold magenta'    ) ~
                   colored( ' → ',  'yellow'      ) ~
                   colored( ~$v // '', 'bold cyan' )
                  } ).join("\n").indent( 2 )
               })
         !! colored( '↳ ', 'yellow' ) ~ colored( $mod, 'bold cyan' );
     }).join( "\n" ).indent( 5 )
  ) if %prov;
}

submethod TWEAK ( ) {

  $!meta-version  = $!meta<meta-version>  // '';
  $!name          = $!meta<name>          // '';
  $!api           = $!meta<api>           // '';
  $!author        = $!meta<author>        // '';
  $!authority     = $!meta<authority>     // '';
  $!description   = $!meta<description>   // '';
  $!source-url    = $!meta<source-url>    // '';
  $!license       = $!meta<license>       // '';
  $!builder       = $!meta<builder>       // '';
  $!auth          = $!meta<auth> // $!meta<author> // '';
  $!ver           = Version.new( $!meta<ver> // $!meta<version> ) if $!meta<ver> // $!meta<version>;
  %!provides      = $!meta<provides>      if $!meta<provides>;
  %!support       = $!meta<support>       if $!meta<support>;
  %!emulates      = $!meta<emulates>      if $!meta<emulates>;
  %!superseded-by = $!meta<superseded-by> if $!meta<superseded-by>;
  %!excludes      = $!meta<excludes>      if $!meta<excludes>;

  @!resources     = flat $!meta<resources> if $!meta<resources>;

 given $!meta<builder> {

    $!builder = Distribution::Builder::MakeFromJSON when 'MakeFromJSON';

  }

  %!depends =
    $!meta<depends> ~~ Array
      ??  runtime => %( requires => $!meta<depends> )
      !!  none($!meta<depends><runtime test build>:exists)
            ?? runtime => none($!meta<depends><requires recommends>:exists)
              ?? requires => $!meta<depends>
              !! $!meta<depends>
            !! $!meta<depends>.map({
                none(.value<requires runtime>:exists) ?? ( .key => %(requires => .value) ) !! .self;
               }) if $!meta<depends>;

  %!depends<build><requires>.append: flat $!meta<build-depends> if $!meta<build-depends>;
  %!depends<test><requires>.append:  flat $!meta<test-depends>  if $!meta<test-depends>;

  %!depends = %!depends.kv.map( -> $k, $v {
    $k => $v.kv.map( -> $k, $v {
      $k => $v.map( -> $depspec {
        $depspec ~~ Array
          ?? $depspec.map( -> $depspec { Pakku::DepSpec.new: $depspec } ).Array
          !! Pakku::DepSpec.new: $depspec;
      }).Array
    }).hash
  });


}


