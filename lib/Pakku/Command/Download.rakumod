use Pakku::Log;
use Pakku::Spec;

unit role Pakku::Command::Download;

multi method fly ( 'download', :@spec! ) {

  log '🧚', header => 'DWN', msg => ~@spec;

  for @spec.map( { Pakku::Spec.new: $_ } ) -> $spec {

    my $meta = self.satisfy: :$spec;

    next without $meta;

    next if self!dont;   # the recommended dist is known, that is the dry run (D8)

    my $dist = self!fetch-dist: $meta, tmp => $*TMPDIR;

    log '🧚', header => 'DWN', msg => ~$dist.prefix;

  }

}
