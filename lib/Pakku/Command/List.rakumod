use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::List;

multi method fly (

  'list',

  Str    :$repo,
  Bool:D :$details = False,

  :@spec = self!repo.map( *.installed ).flat.grep( *.defined ).map( { Pakku::Meta.new( .meta ).Str } ),
  ) { 

  my @repo = $repo ?? self.repo-from-spec( spec => $repo ) !! self!repo;

    
  eager @repo
    ==> map( -> $repo {

      @spec
        ==> sort( )
        ==> map( -> $spec { Pakku::Spec.new: $spec } )
        ==> map( -> $spec {
          $repo.candidates( $spec.name, |$spec.spec )
            ==> map( -> $dist { $dist.id } )
            ==> map( -> $id   { $repo.distribution: $id } )
            ==> map( -> $dist { $dist.meta.item } )
            ==> flat( )
            ==> map( -> $meta { Pakku::Meta.new: $meta } )
      } )
      ==> flat( )
      ==> my @meta;

      log '🐛', header => 'REP', msg => "｢{ $repo.name }｣" if @meta;

      @meta.map( -> $meta { out $meta.gist: :$details} ) unless self!dont;

    } )
    ==> flat( );

}

