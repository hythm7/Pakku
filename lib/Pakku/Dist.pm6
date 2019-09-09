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


  $!meta-version  = $!meta<meta-version>  if $!meta<meta-version>;
  $!name          = $!meta<name>          if $!meta<name>;
  $!source-url    = $!meta<source-url>    if $!meta<source-url>;
  $!auth          = $!meta<auth>          if $!meta<auth>;
  $!author        = $!meta<author>        if $!meta<author>;
  $!authority     = $!meta<authority>     if $!meta<authority>;
  $!api           = $!meta<api>           if $!meta<api>;
  $!ver           = $!meta<ver>           if $!meta<ver>;
  $!version       = $!meta<version>       if $!meta<version>;
  $!description   = $!meta<description>   if $!meta<description>;
  %!provides      = $!meta<provides>      if $!meta<provides>;
  %!files         = $!meta<files>         if $!meta<files>;
  $!source-url    = $!meta<source-url>    if $!meta<source-url>;
  $!license       = $!meta<license>       if $!meta<license>;
  %!support       = $!meta<support>       if $!meta<support>;
  $!builder       = $!meta<builder>       if $!meta<builder>;

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

method Str ( Pakku::Dist:D: --> Str ) {

  my Str $name = "$!name";
  my Str $ver  = ":ver<{$!ver   // ''}>";
  my Str $auth = ":auth<{$!auth // ''}>";
  my Str $api  = ":api<{$!api   // ''}>";

  $name ~ $ver ~ $auth ~ $api;

}
