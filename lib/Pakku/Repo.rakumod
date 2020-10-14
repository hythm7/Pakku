use Pakku::Spec;

unit class Pakku::Repo;
  also is Array;


method candies ( ::?CLASS:D: Pakku::Spec:D $spec ) {

  flat self.map( *.candidates: $spec.name, |$spec.spec );

}

method add ( Distribution::Locally:D :$dist!, :$force ) {

  self.head.install: $dist, :$force;

}

method remove ( ::?CLASS:D: Pakku::Spec:D :$spec! ) {

  self.map( -> $repo {

    sink self.candies( $spec ).map( -> $dist { $repo.uninstall: $dist } )

  } );

}

multi method list ( ::?CLASS:D: :@spec! where *.so ) {

  @spec.map( -> $spec { 

    self
      ==> map( -> $repo {

        $repo.candidates( $spec.name, |$spec.spec )
          ==> map( -> $dist { $dist.id } )
          ==> map( -> $id   { $repo.distribution: $id } )
          ==> map( -> $dist { $dist.meta } )
          ==> flat( );
      } )
      ==> flat( );

  } )
  ==> flat( );

}

multi method list ( ::?CLASS:D: :@spec! where not *.so ) {

  self
    ==> map(  *.installed.map( *.meta ) ) 
    ==> flat( )
    ==> grep( *.defined );
}


multi method new ( ::?CLASS: Str $name ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-name: $name;

  nextwith $repo;
}

multi method new ( ::?CLASS: IO $prefix ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec: "inst#$prefix", next-repo => $*REPO;

  nextwith $repo;
}

multi method new ( ::?CLASS: Any:U $default ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  nextwith flat $repo.repo-chain.grep( CompUnit::Repository::Installation );

}
