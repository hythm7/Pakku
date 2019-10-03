use Pakku::Spec;
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
has $.version;
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

has Pakku::Spec @.deps;

submethod TWEAK ( ) {


  $!meta-version  = $!meta<meta-version> // '';
  $!name          = $!meta<name>         // '';
  $!version       = $!meta<version>      // '';
  $!auth          = $!meta<auth>         // '';
  $!api           = $!meta<api>          // '';
  $!author        = $!meta<author>       // '';
  $!authority     = $!meta<authority>    // '';
  $!description   = $!meta<description>  // '';
  $!source-url    = $!meta<source-url>   // '';
  $!license       = $!meta<license>      // '';
  $!builder       = $!meta<builder>      // '';
  $!ver           = $!meta<ver>          // $!meta<version>;
  %!provides      = $!meta<provides>     if $!meta<provides>;
  %!support       = $!meta<support>      if $!meta<support>;

  @!resources     = flat $!meta<resources> if $!meta<resources>;

  %!depends =
    $!meta<depends> ~~ Array
      ??  runtime => %( require => $!meta<depends> )
      !!  none($!meta<depends><runtime test build>:exists)
            ?? runtime => none($!meta<depends><requires recommends>:exists)
              ?? requires => $!meta<depends>
              !! $!meta<depends>
            !! $!meta<depends>.map({
                none(.value<requires runtime>:exists) ?? ( .key => %(requires => .value) ) !! .self;
               });

  %!depends<build><requires>.append: flat $!meta<build-depends> if $!meta<build-depends>;
  %!depends<test><requires>.append: flat $!meta<test-depends>  if $!meta<test-depends>;

  .say for %!depends;
  #$!depends = runtime => $!meta<depends> unless $!meta<depends>.key

  #  given $!meta<builder> {
  #
  #  $!builder = Distribution::Builder::MakeFromJSON when 'MakeFromJSON';
  #
  #  }

  #  for flat @!depends, @!build-depends, @!test-depends -> $spec {
  #
  #    @!deps.push: Pakku::Spec.new: :$spec;
  #
  #  }

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
    ( gist-deps @!deps        ),
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

sub gist-deps ( Pakku::Spec:D @deps --> Str:D ) {

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
