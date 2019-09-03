use Pakku::Specification;
;
unit class Pakku::Distribution;

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

has Pakku::Specification @.dependencies;

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

  @!resources     = flat $!meta<resources>     if $!meta<resources>;
  @!test-depends  = flat $!meta<test-depends>  if $!meta<test-depends>;
  @!build-depends = flat $!meta<build-depends> if $!meta<build-depends>;
  # @!depends       = flat $!meta<depends>       if $!meta<depends>; 

  for flat @!depends, @!build-depends, @!test-depends -> $spec {

    @!dependencies.push: Pakku::Specification.new: :$spec;

  }

}
