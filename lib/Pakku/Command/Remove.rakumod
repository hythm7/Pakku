use Pakku::Log;
use Pakku::Spec;

unit role Pakku::Command::Remove;
multi method fly ( 'remove', :@spec!, Str :$from ) {

  🧚 qq[RMV: ｢{@spec}｣];

  my @repo = $from ?? self.repo-from-spec( spec => $from ) !! self!repo;


  sink @repo
    ==> map( -> $repo {
      sink @spec.map( -> $str {
        my $spec = Pakku::Spec.new: $str;
        my @dist = $repo.candidates( $spec.name, |$spec.spec );

        🐛 qq[SPC: ｢$spec｣ ‹$repo.prefix()› not added!] unless @dist;

        sink @dist.map( -> $dist {
          $repo.uninstall: $dist;
          🧚 qq[RMV: ｢$dist｣];
        } )

      } ) unless self!dont
    } );
}

