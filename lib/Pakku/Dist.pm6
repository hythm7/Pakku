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
has %.files;
has $.source-url;
has $.license;
has @.build-depends;
has @.test-depends;
has @.resources;
has %.support;
has $.builder;

has Pakku::Spec @.dependencies;

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
  %!files         = $!meta<files>        if $!meta<files>;
  %!support       = $!meta<support>      if $!meta<support>;

  @!resources     = flat $!meta<resources> if $!meta<resources>;

  @!depends       = flat $!meta<depends>.grep:       Str if $!meta<depends>;
  @!test-depends  = flat $!meta<test-depends>.grep:  Str if $!meta<test-depends>;
  @!build-depends = flat $!meta<build-depends>.grep: Str if $!meta<build-depends>;

  given $!meta<builder> {

  $!builder = Distribution::Builder::MakeFromJSON when 'MakeFromJSON';

  }

  for flat @!depends, @!build-depends, @!test-depends -> $spec {

    @!dependencies.push: Pakku::Spec.new: :$spec;

  }

}

multi method gist ( Pakku::Dist:D: :$details where *.not --> Str:D ) {

  ~self;

}

multi method gist ( Pakku::Dist:D: :$details where *.so --> Str:D ) {

  # Ah ya 7osty elsoda yaba yana yama

  qq:to /END/

  name → $!name
  ver  → $!ver
  auth → $!auth
  api  → $!api
  desc → $!description
  {
    "deps ↴" ~ ("\n↳" ~ @!dependencies.join( "\n↳ ")).indent( 5 ) if @!dependencies
  }
  {
    "prov" ~ ("\n↳" ~

     %!provides.kv.map( -> $mod, $path {

       {
         $mod ~ ("\n↳" ~
           $path.kv.map( -> $path, $info {
             $path ~
               ("\n↳" ~
                 $info.kv.map( -> $k, $v {
                   "$k → $v"
                 } ).join( "\n ↳").indent( ++$ )
               ).join( "\n↳").indent( ++$ )
             } ).join( "\n↳" ).indent( ++$ )
           ).join( "\n↳" ).indent( ++$ )
         }
     } ).join( "\n↳").indent( ++$ )
   ) if %!provides
  }
  END

}

method Str ( Pakku::Dist:D: --> Str:D ) {

  $!name ~ ":ver<$!ver>:auth<$!auth>:api<$!api>"

}
