
unit class Pakku::Repo;

has @!repo   is built;

has $!wanted is built = True;

method candies ( ::?CLASS:D: $spec ) {

  flat @!repo.map( *.candidates: $spec.name, |$spec.spec );

}

method remove ( ::?CLASS:D: :$spec! ) {

  @!repo
		==> grep( -> $repo { $repo.name ~~ $!wanted  } )
    ==> map( -> $repo {
      sink self.candies( $spec ).map( -> $dist { $repo.uninstall: $dist } )
    } );

}


multi method list ( ::?CLASS:D: :@spec!,  ) {

  flat @spec.map( -> $spec { 

    @!repo
			==> grep( -> $repo { $repo.name ~~ $!wanted } )
			==> map( -> $repo {
        $repo.candidates( $spec.name, |$spec.spec )
					==> map( -> $dist { $dist.id } )
					==> map( -> $id   { $repo.distribution: $id } )
					==> map( -> $dist { $dist.meta.item } )
					==> flat( );
				} )
				==> flat( );
		} );
}


multi method list ( ::?CLASS:D: ) {

  @!repo
		==> grep( -> $repo { $repo.name ~~ $!wanted } )
    ==> map(  *.installed.map( *.meta.item ) ) 
    ==> flat( )
    ==> grep( *.defined );
}


multi method new ( Str:D $name ) {

  my $home = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  my @repo; 

  @repo.append: $home.repo-chain.grep( CompUnit::Repository::Installation );

  self.bless: wanted => $name, :@repo;

}

multi method new ( IO::Path:D $repo-prefix ) {

  my $home = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec: "inst#$repo-prefix", next-repo => $home;

  CompUnit::RepositoryRegistry.register-name( 'custom', $repo );

  my @repo = $repo;

  @repo.append: $home.repo-chain.grep( CompUnit::Repository::Installation );

  self.bless: wanted => 'custom', :@repo;

}

multi method new ( Any:U ) {

  my $home = CompUnit::RepositoryRegistry.repository-for-name: 'home';

  my @repo; 

  @repo.append: $home.repo-chain.grep( CompUnit::Repository::Installation );

  self.bless: :@repo;

}
