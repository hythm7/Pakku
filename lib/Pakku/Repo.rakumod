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

    self.head.name eq 'core' ?? self !! self.head( * - 1 )
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

  self.head.name eq 'core' ?? self !! self.head( * - 1 )
    ==> map(  *.installed.map( *.meta ) ) 
    ==> flat( )
    ==> grep( *.defined );
}


multi method new ( ::?CLASS: Str $name ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-name: $name;

  nextwith $repo if $name eq 'core';

  my $core = CompUnit::RepositoryRegistry.repository-for-name: <core>;

  $repo.next-repo = $core;

  nextwith flat $repo, $core;
}

multi method new ( ::?CLASS: IO $prefix ) {

  my $core = CompUnit::RepositoryRegistry.repository-for-name: <core>;

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec: "inst#$prefix", next-repo => $core;

  CompUnit::RepositoryRegistry.register-name: $prefix.basename, $repo;
  CompUnit::RepositoryRegistry.use-repository: $repo;


  nextwith flat $repo, $core;
}

multi method new ( ::?CLASS: Any:U $default ) {

  my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  nextwith flat $repo.repo-chain.grep( CompUnit::Repository::Installation );

}
