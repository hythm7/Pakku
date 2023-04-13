use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Core;

unit class Pakku;
  also does Pakku::Core;


multi method fly (

         'add',
         :@spec!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
         :@exclude,

  CompUnit::Repository:D :$repo = CompUnit::RepositoryRegistry.repository-for-name( 'site' ),

) {

  LEAVE self.clear;

  🧚 PRC ~ "｢{@spec}｣";


  @spec
    ==> map(  -> $spec { Pakku::Spec.new: $spec } )
    ==> grep( -> $spec { $force or not self.satisfied: :$spec } )
    ==> unique( as => *.Str )
    ==> map(  -> $spec { self.satisfy: :$spec } )
    ==> map(  -> $dep {

      my @dep = self.get-deps: $dep, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );

      @dep.append: $dep unless $deps ~~ <only>;

      @dep;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => $repo.name // 'custom', # TODO revisit custom repositories
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist, :$precompile;

      self!test: :$dist :$xtest if $test;

    } );

  $*stage.remove-artifacts;

  unless $!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      🧚 BIN ~ "｢{.IO.basename}｣" for Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

    }
  }
}

multi method fly (

         'add',
  IO:D   :$path!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$force      = False,
         :@exclude,

  CompUnit::Repository:D :$repo = CompUnit::RepositoryRegistry.repository-for-name( 'site' ),

) {

  LEAVE self.clear;

  🧚 PRC ~ "｢$path｣";

  my $spec = Pakku::Spec.new: $path;

  return if not $force and self.satisfied: :$spec;

  my $meta = Pakku::Meta.new: $path;

  my @meta = self.get-deps: $meta, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );


  @meta .=  unique( as => *.Str );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  @dist.append: $dist unless $deps ~~ <only>;

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => $repo.name // 'custom', # TODO revisit custom repositories
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist, :$precompile;

      self!test: :$dist :$xtest if $test;

    } );

  $*stage.remove-artifacts;

  unless $!dont {

    if @dist {

      $*stage.deploy;

      my $bin = $*stage.prefix.add( 'bin' ).Str;

      🧚 BIN ~ "｢{.IO.basename}｣" for Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

    }
  }
   
}

multi method fly (

         'upgrade',
         :@spec!,
         :$deps   = True,
  Bool:D :$build  = True,
  Bool:D :$test   = True,
  Bool:D :$xtest  = False,
  Bool:D :$force  = False,
         :@exclude,

  CompUnit::Repository:D :$repo = CompUnit::RepositoryRegistry.repository-for-name( 'site' ),

) {

  LEAVE self.clear;

  🧚 PRC ~ "｢{@spec}｣";

  @spec .= map(  -> $spec { self.upgradable: spec => Pakku::Spec.new: $spec } );

  return unless so @spec;

  @spec .= map( *.Str );

  self.add: :@spec :$deps :$build :$test :$force :@exclude :$repo;

}

multi method fly ( 'test', IO::Path:D :$path!, Bool:D :$xtest  = False, Bool:D :$build = True ) {
  
  LEAVE self.clear;

  🧚 PRC ~ "｢$path｣";

  my $meta = Pakku::Meta.new: $path;

  my @meta = self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  @dist.append: $dist;

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist;

    } );

  self!test: :$dist :$xtest unless $!dont;

  $*stage.remove-artifacts;

}


multi method fly ( 'test', Str:D :$spec!, Bool:D :$xtest  = False, Bool:D :$build = True ) {
   
  LEAVE self.clear;

  🧚 PRC ~ "｢$spec｣";

  my $meta = self.satisfy: spec => Pakku::Spec.new: $spec;

  my @meta = self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  @meta.append: $meta;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;


  my $dist = @dist.tail;

  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist if $build;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist;


    } );

  self!test: :$dist :$xtest unless $!dont;

  $*stage.remove-artifacts;

}

multi method fly ( 'build', IO::Path:D :$path! ) {

  LEAVE self.clear;

  🧚 PRC ~ "｢$path｣";

  my $meta = Pakku::Meta.new: $path;

  my @meta = self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  my $dist = $meta.to-dist: $path;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;


  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist;


    } );

  self!build: :$dist unless $!dont;

  $*stage.remove-artifacts;


}

multi method fly ( 'build', Str:D :$spec! ) {

  LEAVE self.clear;

  🧚 PRC ~ "｢$spec｣";

  my $meta = self.satisfy: spec => Pakku::Spec.new: $spec;

  my @meta = self.get-deps: $meta;

  @meta .=  unique( as => *.Str );

  @meta.append: $meta;

  my @dist = @meta.hyper( degree => $!cores ).map( -> $meta {

    🦋 FTC ~ "｢$meta｣";

    my IO::Path $path = $!tmp.add( $meta.id ).add( now.Num );

    my $cached = $!cache.cached( :$meta ) if $!cache;

    if $cached {

      copy-dir src => $cached, dst => $path;

    } else {

      my $src = $meta.source;

      self.fetch: src => $meta.source, dst => $path;

      $!cache.cache: :$path if $!cache;
    }

    $meta.to-dist: $path;

  } );

  my $*stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => 'home',
    next-repo => $*REPO;

  my $dist = @dist.pop;

  @dist 
    ==> map( -> $dist {
  
      self!build: :$dist;

      🦋 STG ~ "｢$dist｣";

      $*stage.install: $dist;

    } );

  self!build: :$dist unless $!dont;

  $*stage.remove-artifacts;

}

multi method fly ( 'remove', :@spec!, CompUnit::Repository :$repo ) {

  sink @!repo
    ==> grep( $repo )
    ==> map( -> $repo {
      sink @spec.map( -> $str {
        my $spec = Pakku::Spec.new: $str;
        my @dist = $repo.candidates( $spec.name, |$spec.spec );

        sink @dist.map( -> $dist { $repo.uninstall: $dist } )

      } ) unless $!dont
    } );

}

multi method fly ( 'list', :@spec, CompUnit::Repository :$repo, Bool:D :$details = False ) { 
  if @spec {
    
    @spec .= map( -> $spec { Pakku::Spec.new: $spec } );

    @spec.map( -> $spec {

      @!repo
        ==> grep( $repo )
        ==> map( -> $repo {
          $repo.candidates( $spec.name, |$spec.spec )
            ==> map( -> $dist { $dist.id } )
            ==> map( -> $id   { $repo.distribution: $id } )
            ==> map( -> $dist { $dist.meta.item } )
            ==> flat( );
          } )
        ==> flat( );
    } )
    ==> flat( )
    ==> map( -> $meta { Pakku::Meta.new: $meta } )
    ==> map( -> $meta { out $meta.gist: :$details } );


  } else {

  @!repo
    ==> grep( $repo )
    ==> map( *.installed.map( *.meta.item ) )
    ==> flat( )
    ==> grep( *.defined )
    ==> map( -> $meta { Pakku::Meta.new: $meta } )
    ==> map( -> $meta { out $meta.gist: :$details } );
  }

  return;

}

multi method fly ( 'search', :@spec!, Int :$count, Bool:D :$details = False ) {

  @spec
    ==> map( -> $spec { Pakku::Spec.new: $spec                        } )
    ==> map( -> $spec { $!recman.search( :$spec :$count ).Slip   } )
    ==> grep( *.defined                                            )
    ==> map( -> $meta { Pakku::Meta.new( $meta ).gist: :$details } )
    ==> map( -> $meta { out $meta                                } );

  return;

}

multi method fly ( 'download', :@spec! ) {

  sink @spec
    ==> map( -> $spec { Pakku::Spec.new:      $spec               } )
    ==> map( -> $spec { self.satisfy: :$spec               } )
    ==> map( -> $meta {

        🦋 FTC ~ "｢$meta｣";

        my IO::Path $path = $*TMPDIR.add( $meta.id ).add( now.Num );

        my $cached = $!cache.cached( :$meta ) if $!cache;

        if $cached {

          copy-dir src => $cached, dst => $path;

        } else {

          my $src = $meta.source;

          self.fetch: src => $meta.source, dst => $path;

          $!cache.cache: :$path if $!cache;
        }

        🧚 "DWN: ｢$path｣";

      } );
}

multi method fly ( 'config', *%config ) {

  my @arg;
  my %arg;

  my $module      = %config<module>      if %config<module>;
  my $operation   = %config<operation>   if %config<operation>;
  my $recman-name = %config<recman-name> if %config<recman-name>;
  my $log-level   = %config<log-level>   if %config<log-level>;
  my $option      = %config<option>      if %config<option>;

  @arg.push( $module    ) if $module; 
  @arg.push( $operation ) if $operation; 

  %arg<recman-name> =  $recman-name if $recman-name; 
  %arg<log-level>   =  $log-level   if $log-level; 
  %arg<option>      =  $option      if $option; 

  Pakku::Config.new( config-file => %!cnf<pakku><config> ).config( |@arg, |%arg );

}

multi method fly ( 'help',  Str:D :$cmd ) {

  given $cmd {

    when 'add'      { out self!add-help      }
    when 'remove'   { out self!remove-help   }
    when 'list'     { out self!list-help     }
    when 'search'   { out self!search-help   }
    when 'upgrade'  { out self!upgrade-help  }
    when 'build'    { out self!build-help    }
    when 'test'     { out self!test-help     }
    when 'download' { out self!download-help }
    when 'config'   { out self!config-help }
    when 'help'     { out self!help-help     }


    default {
      out (
        self!add-help,
        self!remove-help,
        self!list-help,
        self!search-help,
        self!upgrade-help,
        self!build-help,
        self!test-help,
        self!download-help,
        self!config-help,
        self!pakku-help,
        self!help-help,
      ).join: "\n";
    }
  }
}

multi method fly ( ) {

  self.clear;

  samewith %!cnf<cmd>, |%!cnf{ %!cnf<cmd> };

  ofun
}

proto method fly ( | ) {

  {*}

  CATCH {
    when X::Pakku { 🦗 .message; .resume if $!yolo; nofun }
    default       { 🦗 .gist;                       nofun }
  }
}

