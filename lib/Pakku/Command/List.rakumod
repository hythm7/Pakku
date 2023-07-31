use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::List;

multi method fly ( 'list', :@spec, Str :$repo, Bool:D :$details = False ) { 

  my @repo = $repo ?? self.repo-from-spec( spec => $repo ) !! self!repo;

  if @spec {
    
    @spec .= map( -> $spec { Pakku::Spec.new: $spec } );

    sink @spec.map( -> $spec {

      @repo
        ==> map( -> $repo {

          🐛 "REP: ｢$repo.name()｣";

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
    ==> sort( *.Str )
    ==> map( -> $meta { out $meta.gist: :$details unless self!dont } );


  } else {

  sink @repo
    ==> map( -> $repo {

      🐛 "REP: ｢$repo.name()｣";

      $repo.installed.map( *.meta.item );
      } )
    ==> flat( )
    ==> grep( *.defined )
    ==> map( -> $meta { Pakku::Meta.new: $meta } )
    ==> sort( *.Str )
    ==> map( -> $meta { out $meta.gist: :$details unless self!dont } );
  }

}

