use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::List;

multi method fly ( 'list', Str :$repo, Bool:D :$details = False, :@spec ) {

  my @repo = $repo ?? self.repo-from-spec( spec => $repo ) !! self!repo;

  # everything in the repos we list, not in the chain (D9)
  my @want = @spec || self!installed( :@repo );

  for @repo -> $repo {

    my @meta = @want.sort
      .map( { Pakku::Spec.new: $_ } )
      .map( -> $spec { $repo.candidates( $spec.dependency-specification ).map( { Pakku::Meta.new: $repo.distribution( .id ).meta } ).Slip } );

    log '🐛', header => 'REP', msg => $repo.name if @meta;

    unless self!dont {
      out .gist( :$details ) for @meta;
    }

  }

}
