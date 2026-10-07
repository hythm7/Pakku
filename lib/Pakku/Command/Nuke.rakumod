use X::Pakku;
use Pakku::Log;
use Pakku::Util;

unit role Pakku::Command::Nuke;

# the directories a repo owns; the prefix itself may hold other things (~/.raku has the REPL history)
my constant @repo-dir = <dist sources short precomp bin resources version repo.lock>;

multi method fly ( 'nuke', :@nuke! ) {

  for @nuke -> $what {

    log '🦋', header => 'NUK', msg => $what;

    my @target = do given $what {

      when 'home' | 'site' | 'vendor' | 'core' {
        my $prefix = CompUnit::RepositoryRegistry.repository-for-name( $what ).prefix;
        @repo-dir.map( { $prefix.add: $_ } ).grep( *.e );
      }

      when 'cache' { ( self!cache andthen .cache-dir ) // Empty }
      when 'index' { self!home.add( '.index' ) }
      when 'pakku' { self!home }

    }

    unless @target.grep( *.e ) {
      log '🐛', header => 'NUK', msg => $what, comment => 'nothing to nuke!';
      next;
    }

    if $what eq 'core' and not self!force {
      log '🐞', header => 'NUK', msg => 'core', comment => 'use force to nuke!';
      die X::Pakku::Nuke.new: msg => 'core';
    }

    next if self!dont;

    for @target.grep( *.e ) -> $target {
      $target.d ?? remove-dir( $target ) !! $target.unlink;
    }

    log '🧚', header => 'NUK', msg => $what;

  }

}
