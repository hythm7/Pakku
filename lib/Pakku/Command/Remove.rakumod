use Pakku::Log;
use Pakku::Spec;

unit role Pakku::Command::Remove;


# exact: the spec is the identity of one installed dist, and only that dist goes. A version in a spec is
# a prefix (ver<1.2> is also 1.2.1, ver<chou> also chou.1): cleaning the older release must not take the new one along
multi method fly ( 'remove', :@spec!, Str :$from, Bool:D :$exact = False ) {

  log '🧚', header => 'RMV', msg => ~@spec;

  # Get the current raku `core` dist name
  my @forced  = CompUnit::RepositoryRegistry.repository-for-name('core').candidates('Test');

  my @repo = $from ?? self.repo-from-spec( spec => $from ) !! self!repo;


  sink @repo
    ==> map( -> $repo {

      sink @spec.map( -> $str {

        my $spec = Pakku::Spec.new: $str;
        my @dist = $repo.candidates( $spec.dependency-specification );

        @dist .= grep( { .Str eq $str } ) if $exact;

        log '🐛', header => 'SPC', msg => ~$spec, comment => "{ $repo.prefix}: not added!" unless @dist;

        if any( @dist.map( *.meta ) ) ~~ any( @forced.map( *.meta ) ) {

          unless self!force {

            log '🐞', header => 'RMV', msg => ~$spec, comment => 'use force to remove!';

            die X::Pakku::Remove.new: msg => ~$spec;
          }

        }

        sink @dist.map( -> $dist {

          log '🐞', header => 'RMV', msg => ~$dist unless $dist.meta<name> ~~ $spec.name;

          $repo.uninstall: $dist;

          log '🧚', header => 'RMV', msg => ~$dist;

        } ) unless self!dont;

      } );
    } );
}

