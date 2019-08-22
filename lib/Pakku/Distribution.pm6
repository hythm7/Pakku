unit class Pakku::Distribution;
  also does Distribution;

has $.meta-version;
has $.name;
has $.auth;
has $.author;
has $.authority;
has $.api;
has $.ver;
has $.version;
has $.description;
has $.depends;
has %.provides;
has %.files;
has $.source-url;
has $.license;
has $.build-depends;
has $.test-depends;
has @.resources;
has %.support;
has $.builder;

has IO $.source-path is rw;

method meta ( --> Hash:D ) {
  my %meta;

  %meta.push: ( :$!meta-version  );
  %meta.push: ( :$!name          );
  %meta.push: ( :$.auth          );
  %meta.push: ( :$.ver           );
  %meta.push: ( :$.api           );
  %meta.push: ( :$!description   );
  %meta.push: ( :$!depends       );
  %meta.push: ( :$!build-depends );
  %meta.push: ( :$!test-depends  );
  %meta.push: ( :%!provides      );
  %meta.push: ( :%!files         );
  %meta.push: ( :@!resources     );
  %meta.push: ( :$!license       );
  %meta.push: ( :%!support       );
  %meta.push: ( :$!source-url    );
  %meta.push: ( :$.builder       );

  %meta;
}

method content ($name-path --> IO::Handle:D) {
  IO::Handle.new: path => $name-path;
}
