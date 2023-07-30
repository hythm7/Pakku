use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Build;

multi method fly ( 'build', IO::Path:D :$path! ) {

  🧚 qq[BLD: ｢$path｣];

  my $meta = Pakku::Meta.new: $path;

  my @meta = flat self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  @meta.map( -> $meta { 🦋 qq[DEP: ｢$meta｣] } );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.map( -> $meta {

    🦋 qq[FTC: ｢$meta｣];

    my IO::Path $path = self!tmp.add( $meta.id ).add( now.Num );

    my $cached = self!cache.cached( :$meta ) if self!cache;

    if $cached {

      self.copy-dir: src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      self!cache.cache: :$path if self!cache;
    }

    $meta.to-dist: $path;

  } );

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self.build: :$stage :$dist;

      🦋 qq[STG: ｢$dist｣];

      $stage.install: $dist;


    } );

  self.build: :$dist unless self!dont;

  $stage.remove-artifacts;


}

multi method fly ( 'build', Str:D :$spec! ) {

  🧚 qq[BLD: ｢$spec｣];

  my $meta = self.satisfy: spec => Pakku::Spec.new: $spec;

  my @meta = flat self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  @meta.append: $meta;

  my @dist = @meta.map( -> $meta {

    🦋 qq[FTC: ｢$meta｣];

    my IO::Path $path = self!tmp.add( $meta.id ).add( now.Num );

    my $cached = self!cache.cached( :$meta ) if self!cache;

    if $cached {

      self.copy-dir: src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      self!cache.cache: :$path if self!cache;
    }

    $meta.to-dist: $path;

  } );

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;

  my $dist = @dist.pop;

  @dist 
    ==> map( -> $dist {
  
      self.build: :$stage :$dist;

      🦋 qq[STG: ｢$dist｣];

      $stage.install: $dist;

    } );

  self.build: :$dist unless self!dont;

  $stage.remove-artifacts;

}

