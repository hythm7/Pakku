use X::Pakku;
use Pakku::Log;

unit role Pakku::Command::Nuke;

multi method fly (

  'nuke',
  :@nuke!,

  ) {

  eager @nuke.map( &nuke );


  ## TODO: check permissions

  multi sub nuke ( 'home' ) {

    log '🦋', header => 'NUK', msg => 'home';

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'home';
    my $target = $repo.prefix;
  
    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'home';

    }

  }

  multi sub nuke ( 'site' ) {

    log '🦋', header => 'NUK', msg => 'site';

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'site';
    my $target = $repo.prefix;
 
    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'site';

    }

  }

  multi sub nuke ( 'vendor' ) {

    log '🦋', header => 'NUK', msg => 'vendor';

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'vendor';
    my $target = $repo.prefix;
 
    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'vendor';

    }
   
  }

  multi sub nuke ( 'core' ) {

    log '🦋', header => 'NUK', msg => 'core';

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'core';
    my $target = $repo.prefix;
 
    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!force {

      log '🐞', header => 'NUK', msg => 'core', comment => 'use force to nuke!';

      die X::Pakku::Nuke.new: :dir<core>;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'core';

    }
   
  }


  multi sub nuke ( 'cache' ) {

    log '🦋', header => 'NUK', msg => 'cache';

    my $cache = self!cache;

    unless $cache {

      log '🐛', header => 'NUK', msg => ~$cache, comment => 'no cache!';

      return;
    }

    my $target = $cache.cache-dir;
    
    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'cache';

    }

  }

  multi sub nuke ( 'pakku' ) {

    log '🦋', header => 'NUK', msg => 'pakku';

    my $target = self!home;

    unless $target.d {

      log '🐛', header => 'NUK', msg => ~$target, comment => 'does not exist!';

      return;

    }

    unless self!dont {

      remove-dir $target;

      log '🧚', header => 'NUK', msg => 'pakku';

    }

  }

  my sub remove-dir( IO::Path:D $io --> Nil ) {

    .d ?? remove-dir( $_ ) !! .unlink for $io.dir;

    $io.rmdir;

  }

}


