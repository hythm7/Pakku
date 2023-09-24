use CompUnit::Repository::Staging;

use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Update;

multi method fly (

         'update',
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$clean      = True,
  Str:D  :$in         = 'site',
         :@exclude,

    :@spec = self!repo.map( *.installed ).flat.grep( *.defined ).map( { Pakku::Meta.new( .meta ).Str } )

  ) {

  my @add;

  my %state = self.state: :updates;

  eager @spec.sort
   ==> map( -> $spec { Pakku::Spec.new: $spec } )
   ==> map( -> $spec {

     log '🐛', header => 'SPC', msg => "｢$spec｣";

     self!repo
       ==> map( -> $repo { $repo.candidates( $spec.name , |$spec.spec ) } )
       ==> flat( )
       ==> grep( *.defined )
       ==> map( *.Str )
       ==> my @candy;

     unless @candy {

       log '🐞', header => 'SPC', msg => "｢$spec｣", comment => 'not added!';

       next;

     }

     eager @candy.map( -> $spec {
    
       my $state = %state{ $spec };

       $state.<dep>.grep( Pakku::Spec::Raku )
         ==> grep( *.defined )
         ==> map( *.Str )
         ==> my @missing;

       @missing.map( -> $spec { log '🐞', header => 'DEP', msg => "｢$spec｣", comment => 'missing!' } );

       @add.append: @missing if @missing;

       my $upd = $state.<upd>.grep( *.defined ).head;

       unless $upd {

         log '🐛', header => 'UPD', msg => "｢$spec｣", comment => 'no updates!';

         next;

       }

       log '🦋', header => 'UPD', msg => "｢$upd｣";

       @add.push: $upd.Str;

     } );

   } );

  log '🧚', header => 'UPD', msg => "｢{ @add }｣" if @add;

  @add 
    ==> map(  -> $spec { Pakku::Spec.new: $spec } )
    ==> unique( as => *.Str )
    ==> map(  -> $spec { self.satisfy: :$spec } )
    ==> map(  -> $meta {

      my @meta = flat self.get-deps: $meta, :$deps, |( exclude => @exclude.map( -> $exclude { Pakku::Spec.new( $exclude ) } )  if @exclude );
      @meta .= unique( as => *.Str );

      @meta.append: $meta unless $deps ~~ <only>;

      @meta;

    } )
    ==> flat( )
    ==> unique( as => *.Str )
    ==> my @meta;

  @meta
    ==> grep( -> $meta { not self.satisfied: spec => Pakku::Spec.new: ~$meta } )
    ==> map( -> $meta {

    log '🦋', header => 'FTC', msg => "｢$meta｣";

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

    } )
  ==> my @dist;


  my $repo = self.repo-from-spec: spec => $in;

  unless $repo.can-install {

    log '🐞', header => 'REP', msg => "｢$repo｣", comment => 'can not install!';

    $repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation ).first( *.can-install );

    log '🐞', header => 'REP', msg => "｢$repo｣", comment => 'will be used!' if $repo;

    die X::Pakku::Add.new: dist => @spec unless $repo;

  }

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => self!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $*REPO;

  my $precomp-repo = $stage.prefix.add( 'precomp' ).add( $*RAKU.compiler.id );

  $precomp-repo.mkdir;

  my $supply = watch-recursive( $precomp-repo ).share;

  @dist 
    ==> map( -> $dist {
  
      self.build: :$stage :$dist if $build;

      bar.header: 'STG';
      bar.length: $dist.Str.chars;
      bar.sym:    $dist.Str;
      bar.activate;

      my $processed = 0;
      my $total     = +$dist.meta<provides>.keys;

      my $tap = $supply.tap( -> $module {

      $processed += 1;

      my $percent = $processed / $total * 100;

      bar.percent: $percent;

      bar.show;

      } );

      $stage.install: $dist, :$precompile;

      $tap.close;

      bar.deactivate;

      log '🧚', header => 'STG', msg => "｢$dist｣";

      self.test: :$stage :$dist :$xtest if $test;

    } );

  try $stage.remove-artifacts;

  unless self!dont {

    if @dist {

      $stage.deploy;

      my $bin = $stage.prefix.add( 'bin' ).Str;

      my @bin = Rakudo::Internals.DIR-RECURSE: $bin, file => *.ends-with: none <-m -j -js -m.bat -j.bat -js.bat>;

      log '🐛', header => 'BIN', msg => "｢{ $repo.prefix.add( 'bin' ) }｣", comment => 'binaries added!' if @bin;

      @bin.sort.map( -> $bin { log '🧚', header => 'BIN', msg => "｢{ $$bin.IO.basename }｣" } ).eager;

    }

    if $clean {

      log '🐛', header => 'CLN', msg => '...';

      self.state( :!updates ).values
        ==> grep( *.<cln> )
        ==> map( *.<meta>.Str )
        ==> my @spec;

      samewith 'remove', :@spec if @spec;

    }
  }
}

my sub watch-recursive ( IO $start ) {

  supply {

    my sub watch ( IO::Path:D $io ) {

      whenever $io.watch -> $e {

        CATCH { default { .so } }

        next unless $e.event ~~ FileRenamed;

        if $e.path.IO.d {
          watch( $e.path.IO.resolve );
          next;
        }

        emit $e unless $e.path.IO.extension;
      }
    }

    watch( $start );
  }
}

