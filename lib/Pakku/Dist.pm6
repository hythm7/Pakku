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
has @.depends;
has %.provides;
has $.source-url;
has $.license;
has @.build-depends;
has @.test-depends;
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

  @!depends       = flat $!meta<depends>.grep:       Str if $!meta<depends>;
  @!test-depends  = flat $!meta<test-depends>.grep:  Str if $!meta<test-depends>;
  @!build-depends = flat $!meta<build-depends>.grep: Str if $!meta<build-depends>;

  given $!meta<builder> {

  $!builder = Distribution::Builder::MakeFromJSON when 'MakeFromJSON';

  }

  for flat @!depends, @!build-depends, @!test-depends -> $spec {

    @!deps.push: Pakku::Spec.new: :$spec;

  }

}

multi method gist ( Pakku::Dist:D: :$details where *.not --> Str:D ) {

  ~self;

}

multi method gist ( Pakku::Dist:D: :$details where *.so --> Str:D ) {

  (
    ( gist-name   $!name        ),
    ( gist-ver   ~$!ver         ),
    ( gist-auth   $!auth        ),
    ( gist-api    $!api         ),
    ( gist-desc   $!description ),
    ( gist-deps   @!deps        ),
    ( gist-prov   %!provides    ),
    ( gist-bldr   $!builder     ),
    ( gist-surl   $!source-url  ),
  ).join( "\n" );
}

method Str ( Pakku::Dist:D: --> Str:D ) {

  $!name ~ ":ver<$!ver>:auth<$!auth>:api<$!api>"

}

sub gist-name ( Str:D $name --> Str:D ) { "name → $name" }
sub gist-ver  ( Str:D $ver  --> Str:D ) { "ver  → $ver"  }
sub gist-auth ( Str:D $auth --> Str:D ) { "auth → $auth" }
sub gist-desc ( Str:D $desc --> Str:D ) { "desc → $desc" }
sub gist-api  ( Str:D $api  --> Str:D ) { "api  → $api"  }
sub gist-surl ( Str:D $surl --> Str:D ) { "surl → $surl" }
sub gist-bldr ( Str:D $bldr --> Str:D ) { "bldr → $bldr" }

sub gist-deps ( Pakku::Spec:D @deps --> Str:D ) {

  my $label = 'deps';

  @deps
    ?? "$label\n" ~
        @deps.map( -> $dep {
          "↳ $dep"
        } ).join("\n").indent( $ += 5 )
    !! "$label →";
}

sub gist-prov ( %prov --> Str:D ) {

  # Ah ya 7osty elsoda yaba yana yama
  my $label = 'prov';

  %prov
    ?? "$label \n" ~
        %prov.kv.map( -> $mod, $path {
          "↳ $mod\n" ~
            "{
              $path.kv.map( -> $path, $info {
                "↳ $path\n" ~
                  "{
                    $info.kv.map( -> $k, $v {
                      "↳ $k → { $v // '' }"
                    } ).join("\n").indent( $ += 2 )
                  }"
              }).join( "\n" ).indent( $ += 2 )
            }"
        }).join( "\n" ).indent( $ += 5 )
    !! "$label →";
}
