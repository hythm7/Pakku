use Pakku::Log;
use X::Pakku::Build;

unit role Pakku::Build;


method build ( Distribution::Locally:D :$dist ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  🐞 "BLD: ｢$dist｣";

  my $lib     = $prefix.add: <lib>;
  my $include = "$lib,{ $*repo.path-spec }";
  my @deps    = $dist.deps( :deps<build> ).grep( { .from ~~ 'raku' } );

  my $cmd = $builder

    ?? qq:to/CMD/

    my %meta   := {$dist.meta.perl};

    @deps.map( -> $dep { "use $dep;" } ) 

    ::( "$builder" ).new( :%meta).build(  "$prefix" );

    CMD

    !! qq:to/CMD/;

    require "$file";

    @deps.map( -> $dep { "require ::( \"$dep\" );" } ) 

    ::( 'Build' ).new.build(  "$prefix" );

    CMD


  my $proc = Proc::Async.new: ~$*EXECUTABLE, '-I', $include, '-e', $cmd, cwd => $prefix;

  my $exitcode; 

  react {

    whenever $proc.stdout.lines { 🤓 ( 'BLD: ' ~ $^out ) }
    whenever $proc.stderr.lines { ❌ ( 'BLD: ' ~ $^err ) }

    whenever $proc.stdout.stable( 42 ) {

    🐞 "WAI: ｢{$proc.command}｣";

    }

    whenever $proc.stdout.stable( 420 ) {

      🔔 "TOT: ｢$dist｣";

      $proc.kill;

      $exitcode = 1;

      done;

    }

    whenever $proc.start( cwd => $prefix, :%*ENV ) {

      $exitcode = .exitcode;

      done;

    }
  }

  die X::Pakku::Build.new: :$dist if $exitcode;

  🦋 "BLD: ｢$dist｣"; 
}
