use Pakku::DepSpec;
use Distribution::Builder::MakeFromJSON;

unit class Pakku::Dist;

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

submethod TWEAK ( ) {

  $!meta-version  = $!meta<meta-version>  // '';
  $!name          = $!meta<name>          // '';
  $!auth          = $!meta<auth>          // '';
  $!api           = $!meta<api>           // '';
  $!author        = $!meta<author>        // '';
  $!authority     = $!meta<authority>     // '';
  $!description   = $!meta<description>   // '';
  $!source-url    = $!meta<source-url>    // '';
  $!license       = $!meta<license>       // '';
  $!builder       = $!meta<builder>       // '';
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

method deps (

  Pakku::Dist:D:

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

multi method gist ( Pakku::Dist:D: :$details where *.not --> Str:D ) {

  ~self;

}

multi method gist ( Pakku::Dist:D: :$details where *.so --> Str:D ) {

  (
    (           self          ),
    ( gist-name $!name        ),
    ( gist-ver  $!ver         ),
    ( gist-auth $!auth        ),
    ( gist-api  $!api         ),
    ( gist-desc $!description ),
    ( gist-bldr $!builder     ),
    ( gist-surl $!source-url  ),
    ( gist-deps self.deps     ),
    ( gist-prov %!provides    ),
    (           ''            ),
  ).join( "\n" );
}

method Str ( Pakku::Dist:D: --> Str:D ) {

  $!name ~ ":ver<$!ver>:auth<$!auth>:api<$!api>"

}

sub gist-name ( $name --> Str:D ) { "name → $name" .indent: 2 }
sub gist-ver  ( $ver  --> Str:D ) { "ver  → $ver"  .indent: 2 }
sub gist-auth ( $auth --> Str:D ) { "auth → $auth" .indent: 2 }
sub gist-desc ( $desc --> Str:D ) { "desc → $desc" .indent: 2 }
sub gist-api  ( $api  --> Str:D ) { "api  → $api"  .indent: 2 }
sub gist-surl ( $surl --> Str:D ) { "surl → $surl" .indent: 2 }

sub gist-bldr ( $bldr --> Str:D ) { "bldr → { $bldr // $bldr.^name }" .indent: 2 }

sub gist-deps ( Pakku::DepSpec:D @deps --> Str:D ) {

  my $label = 'deps';

  ( @deps
    ?? "$label\n" ~
        @deps.map( -> $dep {
          "↳ $dep"
        } ).join("\n").indent( 5 )
    !! "$label →";
  ).indent: 2;
}

sub gist-prov ( %prov --> Str:D ) {

  my $label = 'prov';

  ( %prov
    ?? "$label \n" ~
        %prov.kv.map( -> $mod, $path {
          $path ~~ Hash
            ?? "↳ $mod → { $path.keys }\n" ~
                  $path.kv.map( -> $path, $info {
                     $info.kv.map( -> $k, $v {
                      "↳ $k → { $v // '' }"
                     } ).join("\n").indent( 2 )
                  })
            !! "↳ $mod";
        }).join( "\n" ).indent( 5 )
    !! "$label →";
  ).indent: 2;
}
