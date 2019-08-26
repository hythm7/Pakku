unit class Pakku::Distribution;
#also does Distribution;

has $.meta;

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

has Str @.dependencies;

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
  @!depends       = $!meta<depends>       if $!meta<depends>;
  @!build-depends = $!meta<build-depends> if $!meta<build-depends>;
  @!test-depends  = $!meta<test-depends>  if $!meta<test-depends>;
  @!resources     = $!meta<resources>     if $!meta<resources>;

  @!depends       = gather @!depends.deepmap:       *.take;
  @!build-depends = gather @!build-depends.deepmap: *.take;
  @!test-depends  = gather @!test-depends.deepmap:  *.take;
  @!resources     = gather @!resources.deepmap:     *.take;

  @!dependencies  = flat @!depends, @!build-depends, @!test-depends;

}
