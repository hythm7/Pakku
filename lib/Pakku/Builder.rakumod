use Pakku::Log;
use X::Pakku::Build;

unit role Pakku::Builder;


# TODO: Timeout

method build ( Distribution::Locally:D :$dist ) {

  my $builder = $dist.meta<builder>;

  my $file = <Build.rakumod Build.pm6 Build.pm>.map( -> $file { $dist.prefix.add: $file } ).first( *.f );

  return unless $file or $builder;

  🐞 "BLD: ｢$dist｣";

  my $prefix = $dist.prefix;
  my $lib    = $prefix.add: <lib>;
  my @deps   = $dist.deps( :deps<build> ).grep( { .from ~~ 'raku' } );

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


  my $proc = run ~$*EXECUTABLE, '-I', $lib, '-e', $cmd, cwd => $prefix, :out, :err;
  $proc.out.lines.map( 🤓 * );
  $proc.err.lines.map( 🔔  * );

  die X::Pakku::Build.new: :$dist if $proc.exitcode;

  🦋 "BLT: ｢$dist｣"; 

}
