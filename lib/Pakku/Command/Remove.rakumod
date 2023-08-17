use Pakku::Log;
use Pakku::Spec;

unit role Pakku::Command::Remove;


multi method fly ( 'remove', :@spec!, Str :$from ) {

  🧚 qq[RMV: ｢{@spec}｣];

  # Get the current raku `core` dist name
  my @forced  = CompUnit::RepositoryRegistry.repository-for-name('core').candidates('Test');

  my @repo = $from ?? self.repo-from-spec( spec => $from ) !! self!repo;


  sink @repo
    ==> map( -> $repo {

      sink @spec.map( -> $str {

        my $spec = Pakku::Spec.new: $str;
        my @dist = $repo.candidates( $spec.name, |$spec.spec );

        🐛 qq[SPC: ｢$spec｣ ‹$repo.prefix()› not added!] unless @dist;

        if any( @dist.map( *.meta ) ) ~~ any( @forced.map( *.meta ) ) {

          unless self!force {

            🐞 qq[RMV: ｢$spec｣ use force to remove!];

            die X::Pakku::Remove.new: :$spec;
          }

        }

        sink @dist.map( -> $dist {

          $repo.uninstall: $dist;

          🧚 qq[RMV: ｢$dist｣];

        } ) unless self!dont;

      } );
    } );
}

