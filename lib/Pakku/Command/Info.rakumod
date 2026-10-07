use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Info;

# everything pakku knows about a dist: its releases in the ecosystem, what is installed where, who needs it
multi method fly ( 'info', :@spec! ) {

  my %state;   # installed dists with their reverse dependencies, computed once, when needed

  for @spec.map( { Pakku::Spec.new: $_ } ) -> $spec {

    log '🧚', header => 'INF', msg => ~$spec;

    my @release = self!recman ?? self!recman.search( :$spec, :!relaxed, :!latest ).map( { Pakku::Meta.new: $_ } ) !! ();

    my @installed = self!repo.map( -> $repo {
      $repo.candidates( $spec.dependency-specification ).map( { $repo => Pakku::Meta.new( $repo.distribution( .id ).meta ) } ).Slip
    } );

    unless @release or @installed {
      log '🐞', header => 'INF', msg => ~$spec, comment => 'not found!';
      next;
    }

    next if self!dont;

    out ( @release.head // @installed.head.value ).gist: :details;

    # every release, by author, newest first
    for @release.classify( { .auth // '' } ).sort( *.key ) -> ( :key($auth), :value(@meta) ) {
      log '🧚', header => 'VER', msg => @meta.map( *.ver ).unique.join( ' ' ), comment => ( $auth || 'no auth' ) ~ ' ' ~ @meta.map( *.meta<recman> ).unique.join( ' ' );
    }

    for @installed -> ( :key($repo), :value($meta) ) {

      log '🧚', header => 'REP', msg => ~$meta, comment => $repo.name // ~$repo.prefix;

      %state = self.state( :!updates ) unless %state;

      log '🧚', header => 'REV', msg => ~$_ for ( %state{ $meta }<rev> // [] ).sort( *.Str );

    }

  }

}
