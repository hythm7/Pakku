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

    🦋 qq[NUK: ｢home｣];

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'home';
    my $target = $repo.prefix;
  
    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢home｣];

    }

  }

  multi sub nuke ( 'site' ) {

    🦋 qq[NUK: ｢site｣];

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'site';
    my $target = $repo.prefix;
 
    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢site｣];

    }

  }

  multi sub nuke ( 'vendor' ) {

    🦋 qq[NUK: ｢vendor｣];

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'vendor';
    my $target = $repo.prefix;
 
    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢vendor｣];

    }
   
  }

  multi sub nuke ( 'core' ) {

    🦋 qq[NUK: ｢core｣];

    my $repo = CompUnit::RepositoryRegistry.repository-for-name: 'core';
    my $target = $repo.prefix;
 
    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!force {

      🐞 qq[NUK: ｢core｣ use force to nuke!];

      die X::Pakku::Nuke.new: :dir<core>;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢core｣];

    }
   
  }


  multi sub nuke ( 'cache' ) {

    🦋 qq[NUK: ｢cache｣];

    my $cache = self!cache;

    unless $cache {

      🐛 qq[NUK: ｢cache｣ no cache!];

      return;
    }

    my $target = $cache.cache-dir;
    
    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢cache｣];

    }

  }

  multi sub nuke ( 'pakku' ) {

    🦋 qq[NUK: ｢pakku｣];

    my $target = self!home;

    unless $target.d {

      🐛 qq[NUK: ｢$target｣ does not exist!];

      return;

    }

    unless self!dont {

      remove-dir $target;

      🧚 qq[NUK: ｢pakku｣];

    }

  }

  my sub remove-dir( IO::Path:D $io --> Nil ) {

    .d ?? remove-dir( $_ ) !! .unlink for $io.dir;

    $io.rmdir;

  }

}


