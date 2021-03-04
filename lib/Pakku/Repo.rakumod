use Pakku::Log;
use Pakku::Spec;
use X::Pakku::Repo;

unit class Pakku::Repo;

has @!repo;
has $!repo handles < install prefix path-spec > = @!repo.head;

method candies ( ::?CLASS:D: Pakku::Spec:D $spec ) {

  flat @!repo.map( *.candidates: $spec.name, |$spec.spec );

}

method add ( Distribution::Locally:D :$dist!, :$force ) {


  try $.install: $dist, :$force;

  with $! {

    .message.lines.map( { ❌ $^err } );

    die X::Pakku::Repo::Add.new: :$dist;

  }

}

method remove ( ::?CLASS:D: Pakku::Spec:D :$spec! ) {

  @!repo.map( -> $repo {

    sink self.candies( $spec ).map( -> $dist { $repo.uninstall: $dist } )

  } );

}

multi method list ( ::?CLASS:D: :@spec! ) {

  return flat @spec.map( -> $spec { 

    @!repo
      ==> map( -> $repo {

        $repo.candidates( $spec.name, |$spec.spec )
          ==> map( -> $dist { $dist.id } )
          ==> map( -> $id   { $repo.distribution: $id } )
          ==> map( -> $dist { $dist.meta } )
          ==> flat( );
      } )
      ==> flat( );

  } ) if @spec;

  @!repo
    ==> map(  *.installed.map( *.meta ) ) 
    ==> flat( )
    ==> grep( *.defined );
}

multi submethod BUILD ( Str:D :$repo! ) {

  @!repo = CompUnit::RepositoryRegistry.repository-for-name: $repo;

}

multi submethod BUILD ( IO::Path:D :$repo! ) {

  @!repo = CompUnit::RepositoryRegistry.repository-for-spec: "inst#$repo", next-repo => $*REPO;

}

multi submethod BUILD ( ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  @!repo = flat $repo.repo-chain.grep( CompUnit::Repository::Installation );

}
