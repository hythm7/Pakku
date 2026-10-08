use CompUnit::Repository::Staging;

use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Cache;
use Pakku::Util;
use Pakku::Fetch;
use Pakku::Native;
use Pakku::Recman;
use Pakku::Archive;
use Pakku::Grammar::Cmd;

unit role Pakku::Core;

my constant IS-WIN = Rakudo::Internals.IS-WIN();

has %!cnf;

has IO::Path $!home;
has IO::Path $!stage;
has IO::Path $!tmp;

has Int  $!cores;
has Int  $!degree;
has Bool $!dont;
has Bool $!force;
has Bool $!yolo;


has Pakku::Log    $!log;
has Pakku::Cache  $!cache;
has Pakku::Fetch  $!fetch;
has Pakku::Recman $!recman;

has CompUnit::Repository @!repo;


method !home   { $!home   }
method !tmp    { $!tmp    }
method !degree { $!degree }
method !dont   { $!dont   }
method !force  { $!force  }
method !yolo   { $!yolo   }
method !stage  { $!stage  }
method !cache  { $!cache  }
method !fetch  { $!fetch  }
method !recman { $!recman }
method !repo   { @!repo   }

# what a failed step means: yolo logs it and carries on, otherwise the run ends here
method !olo ( X::Pakku:D $x --> Nil ) { $x.log; log '🐞', header => 'OLO', msg => $x.msg; Nil }
method !die ( X::Pakku:D $x )         { $!yolo ?? self!olo( $x ) !! $x.throw }

# the installed dists of @repo, as identity strings
method !installed ( :@repo = @!repo ) { @repo.map( *.installed ).flat.grep( *.defined ).map( { Pakku::Meta.new( .meta ).Str } ) }

# does this dist (by name or by one of its modules) satisfy the spec?
multi sub provided-by ( Pakku::Meta:D $meta, Pakku::Spec::Raku:D $spec --> Bool:D ) {
  ( $meta.name eq $spec.name or ( $meta.meta<provides> // {} ){ $spec.name }:exists ) and $spec.ACCEPTS( $meta.meta );
}
multi sub provided-by ( Pakku::Meta:D $meta, Pakku::Spec::Any:D $spec --> Bool:D ) { so $spec.spec.first( { provided-by $meta, $_ } ) }
multi sub provided-by ( Pakku::Meta:D $meta, Pakku::Spec::All:D $spec --> Bool:D ) { not $spec.spec.first( { not provided-by $meta, $_ } ) }
multi sub provided-by ( $, $ --> Bool:D ) { False }


# what a test or build child sees: the stage first, then the target repo when it is not in this process's
# chain (a custom path), so a serial add's later dists find the ones deployed before them
method !rakulib ( $stage, $repo --> Str:D ) {

  join ',', $stage.path-spec, ( "inst#{ $repo.prefix.absolute }" if $repo and not @!repo.first( *.prefix eq $repo.prefix ) );

}

# run a command, stream its output to the log, kill it after $timeout seconds of silence (0: never);
# the clock starts with the process, so a child that never prints is caught too
method !run ( @cmd, IO::Path:D :$cwd!, Str:D :$header!, Str:D :$what!, Int:D :$timeout = 420 --> Int:D ) {

  my $proc = Proc::Async.new: @cmd, :enc<utf8-c8>;   # a stray byte in a test's output is not a reason to die

  log '🐛', header => $header, msg => ~$proc.command;

  my $last = now;
  my Int $exitcode;
  my $tick = $timeout ?? min( 42, $timeout ) !! 42;

  react {

    whenever $proc.stdout.lines { $last = now; log '🐝', :$header, msg => $_, :!msg-delimit; QUIT { default { log '🐞', :$header, msg => $what, comment => "output lost: { .message }" } } }
    whenever $proc.stderr.lines { $last = now; log '🐞', :$header, msg => $_, :!msg-delimit; QUIT { default { log '🐞', :$header, msg => $what, comment => "output lost: { .message }" } } }

    whenever Supply.interval( $tick, $tick ) {

      my $quiet = now - $last;

      if $timeout and $quiet >= $timeout {

        log '🐞', header => 'TOT', msg => $what, comment => "no output for { $timeout }s, killed!";

        $proc.kill: SIGKILL;

        $exitcode //= 1;

        done;

      }
      elsif $quiet >= 42 { log '🐞', header => 'WAI', msg => ~$proc.command }

    }

    whenever $proc.start( :$cwd, :%*ENV ) {

      $exitcode //= .exitcode || ( .signal ?? 128 + .signal !! 0 );   # a crash is a failure, whatever the exit code says

      done;

      QUIT { default { log '🦗', :$header, msg => $what, comment => .message; $exitcode //= 1; done } }

    }

  }

  $exitcode // 1;

}

method test (
  CompUnit::Repository::Staging:D :$stage!,
  Distribution::Locally:D         :$dist!,
  Bool                            :$xtest,
                                  :$repo,
  ) {

  my @dir = <tests t>;

  @dir.append: <xtest xt> if $xtest;

  my $prefix = $dist.prefix;

  my @test = @dir
    .map( { $prefix.add: $_ } )
    .grep( *.d )
    .map( { Rakudo::Internals.DIR-RECURSE( ~$_, file => *.ends-with( any <.rakutest .t> ) ).Slip } )
    .sort
    .map( *.IO );

  return unless @test;

  %*ENV<RAKULIB> = self!rakulib( $stage, $repo );

  my Int $timeout   = ( %!cnf<test><timeout> // 420 ).Int;
  my     $failed    = False;
  my     $processed = 0;

  bar.header: 'TST';
  bar.length: $dist.Str.chars;
  bar.sym:    $dist.Str;
  bar.activate;

  # one failure is enough: tests already running finish, no new one starts (C5)
  sink @test.hyper( :$!degree :1batch ).map( -> $test {

    unless $failed {

      log '🦋', header => 'TST', msg => $test.basename;

      my $exitcode = self!run: [ $*EXECUTABLE, $test.relative( $prefix ) ], cwd => $prefix, header => 'TST', what => $test.basename, :$timeout;

      $processed += 1;

      bar.percent: $processed / @test * 100;
      bar.show;

      if $exitcode { $failed = True; log '🦗', header => 'TST', msg => $test.basename }

    }

  } );

  bar.deactivate;

  if $failed { self!die( X::Pakku::Test.new: msg => ~$dist ) }
  else       { log '🧚', header => 'TST', msg => ~$dist }

}

method build (
  CompUnit::Repository::Staging:D :$stage!,
  Distribution::Locally:D         :$dist!,
                                  :$repo,
  ) {

  my $prefix  = $dist.prefix.absolute.IO;
  my $builder = $dist.meta<builder>;
  my $file    = <Build.rakumod Build.pm6 Build.pm>.map( { $prefix.add: $_ } ).first( *.f );

  return unless $file or $builder;

  log '🦋', header => 'BLD', msg => ~$dist;

  my @cmd = $*EXECUTABLE.absolute;

  if $builder {

    # the META travels as JSON: its .raku needed the parser to guess block or hash, and it guessed block (C10)
    %*ENV<PAKKU_META> = Rakudo::Internals::JSON.to-json: $dist.meta;

    @cmd.append: '-I', $prefix, '-e', "require $builder; my %meta := Rakudo::Internals::JSON.from-json( %*ENV<PAKKU_META> ); ::( '$builder' ).new( :%meta ).build( '$prefix' );";

  } else {

    @cmd.append: '-e', "require '$file'; ::( 'Build' ).new.build( '$prefix' );"; # -I $prefix breaks Linenoise Build

  }

  %*ENV<RAKULIB> = self!rakulib( $stage, $repo );

  my $exitcode = self!run: @cmd, cwd => $prefix, header => 'BLD', what => ~$dist, timeout => ( %!cnf<build><timeout> // 420 ).Int;

  if $exitcode { self!die( X::Pakku::Build.new: msg => ~$dist ) }
  else         { log '🧚', header => 'BLD', msg => ~$dist }

}

multi method satisfy ( Pakku::Spec::Raku:D :$spec! ) {

  # File::Which has empty dep name
  # should be removed after File::Which is fixed
  return Nil unless $spec.name;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfying!';

  # the index is local and newest-first; the cache only answers when it can not (norecman, offline, no index yet)
  my $found = do {
    CATCH { when X::Pakku::Index { self!no-index( $_ ); Nil } }
    $!recman.recommend( :$spec ) if $!recman;
  }

  $found //= $!cache.recommend( :$spec ).?meta if $!cache;

  my $meta = $found ?? ( try Pakku::Meta.new: $found ) !! Nil;

  log '🐛', header => 'MTA', msg => ~$spec, comment => $!.message with $!;

  unless $meta {

    log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

    return self!die( X::Pakku::Spec.new: msg => ~$spec );

  }

  log '🧚', header => 'MTA', msg => ~$meta;

  $meta;

}

has Bool $!no-index-told = False;

# no usable index (offline without one, every mirror failed): said once, then the cache has its chance
method !no-index ( X::Pakku::Index:D $x --> Nil ) {

  log '🐞', header => 'IDX', msg => $x.msg, comment => $x.comment unless $!no-index-told;

  $!no-index-told = True;

}

# a bin, native library or Perl module is not a Raku dist: pakku can check for it, not install it
multi method satisfy ( :$spec! where Pakku::Spec::Bin | Pakku::Spec::Native | Pakku::Spec::Perl ) {

  log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

  self!die( X::Pakku::Spec.new: msg => ~$spec, comment => 'not a Raku dist, install it yourself' );

}

# a group is not one dist: its members are resolved one by one (see !resolve)
multi method satisfy ( Pakku::Spec::All:D :$spec! ) {

  self!die( X::Pakku::Spec.new: msg => ~$spec, comment => 'a group of dependencies, not one dist' );

}

# alternatives: the first one the recman can recommend, in the order written (S22)
multi method satisfy ( Pakku::Spec::Any:D :$spec! ) {

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfying!';

  for $spec.spec -> $alternative {

    log '🐛', header => 'SPC', msg => ~$alternative, comment => 'trying!';

    my $meta = try samewith spec => $alternative;

    return $meta if $meta;

  }

  log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';

  self!die( X::Pakku::Spec.new: msg => ~$spec );

}


multi method satisfied ( Pakku::Spec::Raku:D :$spec!, :@repo = @!repo --> Bool:D ) {

  return False unless @repo.first( *.candidates( $spec.dependency-specification ) );

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Bin:D :$spec! --> Bool:D ) {

  return False unless find-bin $spec.name;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Native:D :$spec! --> Bool:D ) {

  my \lib = $*VM.platform-library-name( $spec.name.IO, |( version => Version.new( $_ ) with $spec.ver ) ).Str;

  return False unless Pakku::Native.can-load: lib;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Perl:D :$spec! --> Bool:D ) {

  return False unless find-perl-module $spec.name;

  log '🐛', header => 'SPC', msg => ~$spec, comment => 'satisfied!';

  True;
}

multi method satisfied ( Pakku::Spec::Any:D :$spec!, :@repo = @!repo --> Bool:D ) { so $spec.spec.first( -> $spec { samewith :$spec, :@repo } ) }

multi method satisfied ( Pakku::Spec::All:D :$spec!, :@repo = @!repo --> Bool:D ) { not $spec.spec.first( -> $spec { not samewith :$spec, :@repo } ) }


# can this spec be met: installed already, or the recman (or the cache) has it; a group needs all its members
method !resolvable ( $spec --> Bool:D ) {

  given $spec {
    when Pakku::Spec::All  { not .spec.first( -> $member { not self!resolvable( $member ) } ) }
    when Pakku::Spec::Any  { so  .spec.first( -> $member { self!resolvable( $member ) } ) }
    when Pakku::Spec::Raku {
      so self.satisfied( :$spec )
        || ( $!recman and ( try $!recman.recommend( :$spec ) ).defined )
        || ( $!cache  and $!cache.recommend( :$spec ).defined )
    }
    default { self.satisfied( :$spec ) }
  }

}

# the dependencies of a dist, as the dists to install for them (see !resolve)
method get-deps ( Pakku::Meta:D $meta, :$deps = True, Bool:D :$contained = False, :@exclude ) {

  self!resolve: $meta.deps( :$deps ), :$deps, :$contained, :@exclude, :!top;

}

# the dists to install for @spec: dependencies first, each one once, nothing that is already
# installed (unless contained); a spec may be satisfied by a dist chosen earlier in this very
# resolution, so Foo:ver<0.2+> and a bare Foo end up as one Foo (B17)
method !resolve ( @spec, :$deps = True, Bool:D :$contained = False, :@exclude, Bool:D :$top = True --> Array ) {

  my @meta;
  my %done;
  my @excluded = @exclude.map( *.name );   # by name: Foo:ver<1+> in a META is still Foo (B11)

  my sub resolve ( $spec, Bool:D :$top = False ) {

    return if %done{ $spec.id }++;

    # a group: every member on its own (S22: a list inside the alternatives is a list of dependencies)
    if $spec ~~ Pakku::Spec::All { resolve $_ for $spec.spec; return }

    # alternatives: the first one that can be met, in the order written (S22); a group counts when all of it can
    if $spec ~~ Pakku::Spec::Any {

      return if not $top and not $contained and self.satisfied( :$spec );

      my $pick = $spec.spec.first( -> $alternative { self!resolvable( $alternative ) } );

      without $pick {
        log '🐞', header => 'SPC', msg => ~$spec, comment => 'could not satisfy!';
        self!die( X::Pakku::Spec.new: msg => ~$spec );
        return;
      }

      resolve $pick, :$top;
      return;

    }

    return if $spec ~~ Pakku::Spec::Raku and $spec.name eq any @excluded;
    return if @meta.first( -> $meta { provided-by $meta, $spec } );
    return if not $top and not ( $contained and $spec ~~ Pakku::Spec::Raku | Pakku::Spec::Any ) and self.satisfied( :$spec );

    my $meta = self.satisfy: :$spec;

    return without $meta;   # yolo: carry on without it

    resolve $_ for $meta.deps( :$deps );

    @meta.push: $meta unless ( $top and $deps ~~ 'only' ) or @meta.first( *.Str eq $meta.Str );   # a cycle may name it twice

  }

  resolve $_, :$top for @spec;

  @meta;

}

# a dist's files, from the cache or the ecosystem, as a Distribution ready to stage
method !fetch-dist ( Pakku::Meta:D $meta, IO::Path:D :$tmp = $!tmp ) {

  log '🦋', header => 'FTC', msg => ~$meta;

  my $path = $tmp.add( $meta.id ).add( now.Num );

  my $cached = $!cache.cached( :$meta ) if $!cache;

  if $cached {

    copy-dir src => $cached, dst => $path;

  } else {

    self.fetch: src => $meta.source, dst => $path, sha1 => $meta.meta<sha1>;

    $!cache.cache: :$path if $!cache;

  }

  log '🧚', header => 'FTC', msg => ~$meta;

  $meta.to-dist: $path;

}

# all of them, in parallel; a failed fetch ends the run, unless yolo
method !fetch-dists ( @meta --> Array ) {

  my @fetched = @meta.hyper( degree => $!degree, :1batch ).map( -> $meta { ( try self!fetch-dist: $meta ) // $! } );

  for @fetched.grep( Exception ) { $_ ~~ X::Pakku ?? self!die( $_ ) !! .rethrow }

  my @dist = @fetched.grep( Distribution );

  @dist;

}

# precomp files land in directories that appear as the stage fills: watch each one as it shows up,
# and list what landed in it before the watch was armed (the first file of a bucket, C6)
method !watch-recursive ( IO::Path:D $start --> Supply:D ) {

  my %seen;

  supply {

    my sub file ( IO::Path:D $file, Bool:D :$emit ) {
      return if $file.extension;                       # precomp files have none; .lock, .repo-id ... do
      return unless $file.f;                           # a directory, or already gone again
      emit $file.Str if $emit and not %seen{ $file.Str };
      %seen{ $file.Str } = True;
    }

    my sub watch ( IO::Path:D $dir, Bool:D :$emit ) {

      whenever $dir.watch -> $e {

        CATCH { default { .so } }

        next unless $e.event ~~ FileRenamed;

        my $path = $e.path.IO;

        if $path.d { watch $path.resolve, :emit; next }

        file $path, :emit;

      }

      # already there: what was created before this watch (silently for the start directory, those are older dists)
      for $dir.dir -> $entry { $entry.d ?? watch( $entry.resolve, :$emit ) !! file( $entry, :$emit ) }

    }

    watch $start, :!emit;

  }

}

# install one dist into the staging repo, with its build before and its tests after
method !stage-dist ( $stage, Distribution::Locally:D $dist, Bool:D :$build!, Bool:D :$test!, Bool:D :$xtest!, Bool:D :$precompile!, :$repo ) {

  self.build: :$stage, :$dist, :$repo if $build;

  my $precomp-dir = $stage.prefix.add( 'precomp' ).add( $*RAKU.compiler.id );
  my $dist-dir    = $stage.prefix.add: 'dist';

  $precomp-dir.mkdir;
  $dist-dir.mkdir;

  my @tap;

  if $precompile {

    bar.header: 'STG';
    bar.length: $dist.Str.chars;
    bar.sym:    $dist.Str;
    bar.activate;

    my $processed      = 0;
    my $total          = +$dist.meta<provides>.keys || 1;
    my $dist-meta-file = $dist-dir.add( $dist.id );

    my %hash-to-name;

    # the dist's META lands in dist/<id> during install: it maps precomp hashes back to module names
    @tap.push: $dist-dir.watch.tap( -> $event {

      if $event.path ~~ $dist-meta-file and $event.event ~~ FileChanged {

        my %provides = try Rakudo::Internals::JSON.from-json( $dist-meta-file.slurp ).<provides>;

        %provides.map( { %hash-to-name{ .value.values.head.<file> } = .key } );

      }

    } );

    @tap.push: self!watch-recursive( $precomp-dir ).tap( -> $path {

      log '🦋', header => 'CMP', msg => %hash-to-name{ $path.IO.basename } // $path.IO.basename;

      $processed += 1;

      bar.percent: $processed / $total * 100;
      bar.show;

    } );

  }

  $stage.install: $dist, :$precompile;

  .close for @tap;

  bar.deactivate if $precompile;

  log '🧚', header => 'STG', msg => ~$dist;

  self.test: :$stage, :$dist, :$xtest, :$repo if $test;

}

# move the staged dists into the target repo; reset keeps the staging repo for the next dist (serial)
method !deploy ( $stage, $repo, Bool:D :$reset = False ) {

  return if $!dont;

  try $stage.remove-artifacts; # trying for Windows

  self!move-in: $stage, $repo;

  # one line per script: not the per-backend wrappers (-m, -j, -js) nor the .raku / .bat variants Rakudo writes
  my @bin = Rakudo::Internals.DIR-RECURSE( $stage.prefix.add( 'bin' ).Str, file => { not .IO.extension and not .ends-with( any <-m -j -js> ) } ).sort;

  log '🐛', header => 'BIN', msg => ~$repo.prefix.add( 'bin' ), comment => 'binaries added!' if @bin;

  log '🧚', header => 'BIN', msg => .IO.basename for @bin;

  if $reset {

    try $stage.self-destruct; # trying for Windows

    $stage.prefix.add( 'precomp' ).add( $*RAKU.compiler.id ).mkdir;
    $stage.prefix.add( 'dist' ).mkdir;

  }

}

# what Rakudo's Staging.deploy does, with one difference: every file is written next to its
# destination and renamed over it. A plain copy truncates the old file in place, and a running
# raku (this very pakku, reinstalling itself) has those precompiled files memory mapped: segfault.
method !move-in ( $stage, $repo --> Nil ) {

  my $from    = $stage.prefix.absolute;
  my $relpath = $from.chars;
  my $to      = $repo.prefix;

  for Rakudo::Internals.DIR-RECURSE( $from ) -> $path {

    my $destination = $to.add( $path.substr( $relpath ) );
    my $part        = $destination.sibling( $destination.basename ~ ".$*PID.part" );

    $destination.parent.mkdir;

    $path.IO.copy: $part;

    try unlink $destination if IS-WIN;   # rename over an existing file is not atomic there

    $part.rename: $destination;

  }

}

# a staging repo named after the target: dists are built, installed and tested there, then deployed
method !stage-dists (
  @dist,
         :$repo!,
  Bool:D :$serial     = False,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$deploy     = True,
  ) {

  # precompilation in the stage resolves modules through the chain: a target repo outside it
  # (a custom path) goes first, so a serial add's later dists find the ones deployed before them
  my $next = @!repo.first( *.prefix eq $repo.prefix ) ?? $*REPO !! $repo;

  my $stage := CompUnit::Repository::Staging.new:
    prefix    => $!stage.add( now.Num ),
    name      => $repo.name,
    next-repo => $next;

  for @dist -> $dist {

    self!stage-dist: $stage, $dist, :$build, :$test, :$xtest, :$precompile, :$repo;

    self!deploy( $stage, $repo, :reset ) if $serial and $deploy;

  }

  self!deploy( $stage, $repo ) if $deploy and not $serial and @dist;

  $stage;

}

# stage a dist with its dependencies, without deploying, and do something with it there: test it, build it
method !try-out ( Pakku::Meta:D $meta, &do, :$dist is copy, Bool:D :$build = True, Bool:D :$build-target = $build ) {

  my @meta = self!resolve: $meta.deps( :deps ), :!top;

  log '🦋', header => 'DEP', msg => ~$_ for @meta;

  my @dist = self!fetch-dists: @meta;

  $dist //= self!fetch-dist: $meta;

  my $stage = self!stage-dists: @dist, repo => CompUnit::RepositoryRegistry.repository-for-name( 'home' ), :$build, :!test, :!precompile, :!deploy;

  self!stage-dist: $stage, $dist, build => $build-target, :!test, :!xtest, :!precompile;

  do( $stage, $dist ) unless $!dont;

  try $stage.remove-artifacts;

}

# a path from the command line: a dist directory as it is, a tarball extracted, a .git directory cloned
method !dist-path ( IO::Path:D $path --> IO::Path:D ) {

  return self!fetch-path( ~$path ) if $path.f;
  return self!fetch-path( ~$path ) if $path.d and $path.basename.ends-with( '.git' );

  $path;

}

# a dist from somewhere else than the ecosystem: a tarball (local or URL) or a git repository
method !fetch-path ( Str:D $src --> IO::Path:D ) {

  my $dst = $!tmp.add( sha1( $src ) ).add( now.Num );

  $src ~~ / ^ 'git@' | ^ 'git://' | '.git' [ '#' <-[\s]>* ]? $ /
    ?? $!fetch.clone( url => $src, :$dst )
    !! self.fetch( src => $src, :$dst );

  $dst;

}

# fez names a tarball after its SHA-1: compare, when a sha1 tool is around (A10)
method !verify ( IO::Path:D $archive, Str:D $expected --> Nil ) {

  my @cmd = find-bin( 'sha1sum'  ) ?? ( 'sha1sum', ~$archive )
         !! find-bin( 'shasum'   ) ?? ( 'shasum', '-a', '1', ~$archive )
         !! find-bin( 'certutil' ) ?? ( 'certutil', '-hashfile', ~$archive, 'SHA1' )
         !! ();

  unless @cmd {
    log '🐛', header => 'FTC', msg => ~$archive, comment => 'no sha1 tool, not verified';
    return;
  }

  my $out = run( |@cmd, :out, :err ).out.slurp( :close );

  my $got = $out.lines.map( *.lc.subst( / \s /, '', :g ) ).first( / ^ <xdigit> ** 40 / ).?substr( 0, 40 );

  without $got {
    log '🐛', header => 'FTC', msg => ~$archive, comment => 'no sha1 from ' ~ @cmd.head ~ ', not verified';
    return;
  }

  if $got ne $expected.lc {
    try unlink $archive;
    die X::Pakku::Fetch.new: msg => ~$archive, comment => "checksum mismatch! expected $expected, got $got";
  }

  log '🐛', header => 'FTC', msg => ~$archive, comment => 'sha1 ok';

}

# the repo to install into: the one asked for, or the first in the chain that takes dists
method !install-repo ( Str:D $spec, Str:D $what ) {

  my $repo = repo-from-spec $spec;

  return $repo if $repo.can-install;

  log '🐞', header => 'REP', msg => ~$repo.prefix, comment => 'can not install!';

  $repo = @!repo.first( *.can-install );

  die X::Pakku::Add.new: msg => $what, comment => 'no repo to install into!' unless $repo;

  log '🐞', header => 'REP', msg => ~$repo.prefix, comment => 'will be used!';

  $repo;

}


multi method fetch ( Str:D :$src!, IO::Path:D :$dst!, :$sha1 ) {

  log '🐛', header => 'FTC', msg => ~$src;

  log '🐝', header => 'FTC', msg => ~$src, comment => ~$dst;

  mkdir $dst;

  my $archive = $dst.add( $dst.basename ~ '.tar.gz' );

  # index sources are already valid URLs (REA's are even pre-encoded): never re-encode them
  retry { $!fetch.download: url => $src, dst => $archive, progress => $!degree == 1 };

  self!verify( $archive, $_ ) with $sha1;   # fez names its tarballs after their SHA-1, the index said so

  log '🐛', header => 'EXT', msg => ~$archive;

  {
    # a rejected or corrupt archive must not leave a half-extracted dist behind
    CATCH { when X::Pakku::Archive { try remove-dir $dst; .rethrow } }

    extract :$archive, :$dst;
  }

  log '🐛', header => 'RMV', msg => ~$archive;

  unlink $archive;

  log '🐛', header => 'FTC', msg => ~$dst;

}

multi method fetch ( IO::Path:D :$src!, IO::Path:D :$dst! ) {

  log '🐛', header => 'FTC', msg => ~$src;

  log '🐝', header => 'FTC', msg => ~$src, comment => $dst;

  copy-dir :$src :$dst;

  log '🐛', header => 'FTC', msg => ~$dst;

}

# is $a an older release of the same dist than $b? (api counts only when both have one, C15)
my sub older ( Pakku::Meta:D $a, Pakku::Meta:D $b --> Bool:D ) {

  my $ver = version( $a.ver ) cmp version( $b.ver );

  return True  if $ver ~~ Less;
  return False if $ver ~~ More;

  $a.api.defined and $b.api.defined and version( $a.api ) < version( $b.api );

}

method state ( :$updates = True ) {

  my %state;

  @!repo
    ==> map( *.installed )
    ==> grep( *.defined )
    ==> flat(  )
    ==> map( { Pakku::Meta.new: .meta } )
    ==> my @meta;

    spinner.header: 'STT';
    spinner.frames: @meta.map( *.Str );
    spinner.activate;

    @meta.map( -> $meta { 

      log '🐛', header => 'STT', msg => ~$meta;

      unless %state{ $meta }:exists {

        %state{ $meta }.<dep> = [];
        %state{ $meta }.<rev> = [];
        %state{ $meta }.<upd> = [];

      }

      %state{ $meta }.<meta> = $meta;

      my @upd;

      if $updates and $!recman {

        my $spec  = Pakku::Spec.new: $meta.name ~ ( ":auth<{ $meta.auth }>" if $meta.auth );
        my $found = $!recman.recommend: :$spec;

        with $found {
          my $newer = Pakku::Meta.new: $found;
          @upd.push: $newer if latest-first( $found, $meta ) ~~ Less and not self.satisfied( spec => Pakku::Spec.new: ~$newer );
        }

      }

      if @upd {
        %state{ $meta  }.<upd> .append: @upd;
      }

      sink $meta.deps( :deps ).grep( Pakku::Spec::Raku ).grep( *.name.so ).map( -> $spec {

        log '🐛', header => 'SPC', msg => ~$spec;

        @!repo
          ==> map( -> $repo { $repo.candidates( $spec.dependency-specification ).head } )
          ==> grep( *.defined )
          ==> my @candy;

        my $candy = @candy.head;

        unless $candy {

          log '🐛', header => 'SPC', msg => ~$spec, comment => 'missing!';

          %state{ $meta }.<dep> .push: $spec;

          next;
        }

        my $dep = Pakku::Meta.new: $candy.read-dist( )( $candy.id );

        log '🐛', header => 'DEP', msg => ~$dep;

        %state{ $meta }.<dep> .push: $dep;
        %state{ $dep  }.<rev> .push: $meta;

      } );

      spinner.next;

  } );

  spinner.deactivate;

  # an older release of a dist nobody depends on is cleanable: same name and the same author (C12)
  my %release;

  %release{ .name ~ '|' ~ ( .auth // '' ) }.push: $_ for %state.values.map( *.<meta> );

  %state.values
    ==> grep( *.<rev>.not )
    ==> map( *.<meta> )
    ==> grep( -> $meta { so %release{ $meta.name ~ '|' ~ ( $meta.auth // '' ) }.first( -> $other { older $meta, $other } ) } )
    ==> map( -> $meta { %state{ $meta }<cln> = True } );

  %state;
}

method repo-from-spec ( Str :$spec ) { repo-from-spec $spec }

method clear ( ) {

  for $!tmp, $!stage -> $dir {

    next unless $dir.d;

    # a child may still hold a file for a moment (a precompilation just finished): try again
    for 1 .. 3 { last if try { remove-dir $dir; True }; sleep 0.2 }

    log '🐛', header => 'CLR', msg => ~$dir, comment => 'could not remove!' if $dir.d;

  }

}

# what runs that crashed or were killed left behind; another process's directories are its own
method sweep ( ) {

  for $!home.add( '.tmp' ), $!home.add( '.stage' ) -> $dir {

    next unless $dir.d;

    for $dir.dir.grep( *.d ) -> $old { try remove-dir $old if now - $old.modified > 86400 }

  }

}

method !cnf ( ) { %!cnf }

submethod BUILD ( :%!cnf! ) {

  $!home = %!cnf<pakku><home>;

  my $pretty   = %!cnf<pakku><pretty>  // True;
  my $bar      = %!cnf<pakku><bar>     // True;
  my $spinner  = %!cnf<pakku><spinner> // True;
  my $cores    = %!cnf<pakku><cores>   //  $*KERNEL.cpu-cores;;
  my $verbose  = %!cnf<pakku><verbose> // 'info';
  my %level    = %!cnf<log>            // {};

  $!log    = Pakku::Log.new: :$pretty :$bar :$spinner :$verbose :%level;
  
  %*ENV
    ==> grep( *.key.starts-with( any <RAKU PAKKU> ) )
    ==> map( -> $env { log '🐝', header => 'ENV', msg => $env.key,  comment => $env.value } );

  log '🐝', header => 'CNF', msg => 'verbose', comment => ~$verbose;
  log '🐝', header => 'CNF', msg => 'bar',     comment => ~$bar;
  log '🐝', header => 'CNF', msg => 'spinner', comment => ~$spinner;

  log '🐝', header => 'CNF', msg => 'home', comment => ~$!home;

  $!stage  = $!home.add( '.stage' ).add( $*PID );   # one per process: another pakku must not clear it

  log '🐝', header => 'CNF', msg => 'stage', comment => ~$!stage;

  my $cache-conf = bool-word %!cnf<pakku><cache>;
  my $cache-dir  = $!home.add( '.cache' ); 

  with $cache-conf {
    $cache-dir = $cache-conf unless $cache-conf === True;  
  }

  $!cache = Pakku::Cache.new:  :$cache-dir if $cache-dir;

  log '🐝', header => 'CNF', msg => 'cache', comment => ~$cache-dir;

  $!tmp = $!home.add( '.tmp' ).add( $*PID );

  log '🐝', header => 'CNF', msg => 'tmp', comment => ~$!tmp;

  $!dont  = %!cnf<pakku><dont> // False;

  log '🐝', header => 'CNF', msg => 'dont', comment => ~$!dont;

  $!force  = %!cnf<pakku><force> // False;

  log '🐝', header => 'CNF', msg => 'force', comment => ~$!force;

  $!yolo  = %!cnf<pakku><yolo> // False;

  log '🐝', header => 'CNF', msg => 'yolo', comment => ~$!yolo;

  die X::Pakku::Cnf.new: msg => 'cores', comment => "$cores: not a positive integer!" unless $cores ~~ Int:D | /^ \d+ $/ and +$cores > 0;

  $!cores  = +$cores;

  log '🐝', header => 'CNF', msg => 'cores', comment => ~$!cores;

  $!degree = %!cnf<pakku><async> ?? $!cores !! 1;

  log '🐝', header => 'CNF', msg => 'degree', comment => ~$!degree;

  my $recman   = bool-word %!cnf<pakku><recman>;
  my $norecman = bool-word %!cnf<pakku><norecman>;
  my $refresh  = bool-word %!cnf<pakku><refresh>;

  my @recman = ( %!cnf<recman> // [] ).flat;

  @recman .= grep: { .<name> !~~ $norecman } if $norecman;
  @recman .= grep: { .<name>  ~~ $recman   } if $recman;

  $!fetch  = Pakku::Fetch.new;

  $!recman = Pakku::Recman.new: :$!fetch, store => $!home.add( '.index' ), :@recman, :$refresh if @recman;

  # an old config file may list only the retired recman.pakku.org: fall back to the built-in ecosystems
  if @recman and not $!recman.names and not ( $recman ~~ Str or $norecman ) {

    log '🐞', header => 'REC', msg => 'config', comment => 'no usable recman configured, using the built-in ecosystems (pakku config recman reset)';

    @recman = Rakudo::Internals::JSON.from-json( %?RESOURCES<config.json>.slurp )<recman>.flat;

    $!recman = Pakku::Recman.new: :$!fetch, store => $!home.add( '.index' ), :@recman, :$refresh;

  }

  @recman.map( -> $recman { log '🐝', header => 'CNF', msg => 'recman', comment => $recman<name> ~ ' ' ~ ( $recman<mirrors> // $recman<location> // '' ).List.map( { redact ~$_ } ).join( ' ' ) } );

  @!repo = $*REPO.repo-chain.grep( CompUnit::Repository::Installation );

  log '🐝', header => 'CNF', msg => 'repos', comment => ~@!repo;

}


method metamorph ( ) {

  CATCH {

    Pakku::Log.new: :pretty :verbose<debug>;

      when X::Pakku::Cmd { .log; nofun; exit 1 }

      when X::Pakku::Cnf { .log; nofun; exit 1 }

      default { log '🦗', header => 'CNF', msg => .gist, :!msg-delimit; nofun; exit 1 }
  }

  my $home = $*HOME.add( '.pakku' );

  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::CmdActions );

  die X::Pakku::Cmd.new: msg => ~@*ARGS, comment => 'unknown command or option, see: pakku help' unless $cmd;

  my %cmd = $cmd.made;

  my %env = get-env;

  my %cnf = hashmerge %env, %cmd;

  my %default = Rakudo::Internals::JSON.from-json: %?RESOURCES<config.json>.slurp;


  # a config file named on the command line or by PAKKU_CONFIG must exist, unless this very run creates it
  if %cnf<pakku><config>:exists and not ( %cmd<cmd> eq 'config' and ( %cmd<config><operation> // '' ) eq 'new' ) {

    die X::Pakku::Cnf.new: msg => ~%cnf<pakku><config>, comment => 'no such config file! to create: pakku config <path> config new' unless %cnf<pakku><config>.IO.f;

  }

  %cnf<pakku><config> //= $home.add( 'config.json' );

  my $config-file = %cnf<pakku><config>.IO;

  if $config-file.f {

    my $cnf = Rakudo::Internals::JSON.from-json: slurp $config-file.IO;

    die X::Pakku::Cnf.new: msg => ~$config-file unless defined $cnf;

    %cnf =  hashmerge $cnf, %cnf;

  }

  %cnf = hashmerge %default, %cnf;

  %cnf<pakku><home> = $home;

  self.bless( :%cnf );

}

# borrowed from Hash::Merge:cpan:TYIL to fix #6
# deep merge, the source wins; a hash only merges into a hash (a null in a config file replaces, it does not crash)
# "true" and "false" in a config file written by hand (or by an older pakku) mean the booleans
my sub bool-word ( $value ) {
  return $value unless $value ~~ Str:D;
  $value.lc eq 'true' ?? True !! $value.lc eq 'false' ?? False !! $value;
}

my sub hashmerge ( %merge-into, %merge-source ) {

  for %merge-source.keys -> $key {
    if %merge-into{ $key } ~~ Hash and %merge-source{ $key } ~~ Hash {
      hashmerge %merge-into{ $key }, %merge-source{ $key };
    }
    else { %merge-into{ $key } = %merge-source{ $key } }
  }

  %merge-into;
}

my sub repo-from-spec ( Str $spec ) {

  return CompUnit::RepositoryRegistry.repository-for-name( $spec ) if $spec ~~ any <home site vendor core>;

  return CompUnit::Repository unless $spec;

  my $repo-spec = CompUnit::Repository::Spec.from-string( $spec, 'inst' );
  my $name = $repo-spec.options<name> // 'custom-lib';

  my $repo = CompUnit::RepositoryRegistry.repository-for-spec( $repo-spec );

  CompUnit::RepositoryRegistry.register-name( $name, $repo );

  # a repo outside the chain gets the chain behind it, so what is installed there can load its
  # dependencies from home/site/core (Rakudo hands out one object per prefix: set it, do not recreate it)
  $repo.next-repo = $*REPO unless $repo.next-repo.defined;

  $repo;
}

my sub find-perl-module ( Str:D $name --> Bool:D ) {

  return True if run('perl', "-M$name", '-e 1', :err).exitcode == 0;

  return False;
}

# PAKKU_* environment variables, lowest precedence after the built-in defaults
my sub get-env ( ) {

  my %env;

  my sub bool ( Str:D $name, Str:D $value ) {
    given $value.lc {
      when '1' | 'true'  | 'yes' | 'on'  { True  }
      when '0' | 'false' | 'no'  | 'off' | '' { False }
      default { die X::Pakku::Cnf.new: msg => $name, comment => "$value: not a boolean (true/false)!" }
    }
  }

  my sub deps ( Str:D $value ) { $value eq 'only' ?? 'only' !! bool( 'deps', $value ) }

  my sub seconds ( Str:D $name, Str:D $value ) { $value ~~ / ^ \d+ $ / ?? +$value !! die X::Pakku::Cnf.new: msg => $name, comment => "$value: not a number of seconds!" }

  my sub positive ( Str:D $name, Str:D $value ) { $value ~~ / ^ \d+ $ / && +$value > 0 ?? +$value !! die X::Pakku::Cnf.new: msg => $name, comment => "$value: not a positive integer!" }

  # general: name => [ config key, converter ]
  my %general =
    PAKKU_VERBOSE  => [ 'verbose',  { $_ } ],
    PAKKU_CORES    => [ 'cores',    { positive 'PAKKU_CORES', $_ } ],
    PAKKU_RECMAN   => [ 'recman',   { $_ ~~ / ^ [ true | 1 ] $ / ?? True !! $_ } ],
    PAKKU_NORECMAN => [ 'norecman', { $_ ~~ / ^ [ true | 1 ] $ / ?? True !! $_ } ],
    PAKKU_CONFIG   => [ 'config',   { .IO } ],
    PAKKU_CACHE    => [ 'cache',    { $_ ~~ / ^ [ 0 | 1 | true | false | yes | no | on | off ] $ / ?? bool( 'PAKKU_CACHE', $_ ) !! $_ } ],
    PAKKU_DONT     => [ 'dont',     { bool 'PAKKU_DONT',    $_ } ],
    PAKKU_FORCE    => [ 'force',    { bool 'PAKKU_FORCE',   $_ } ],
    PAKKU_YOLO     => [ 'yolo',     { bool 'PAKKU_YOLO',    $_ } ],
    PAKKU_PRETTY   => [ 'pretty',   { bool 'PAKKU_PRETTY',  $_ } ],
    PAKKU_ASYNC    => [ 'async',    { bool 'PAKKU_ASYNC',   $_ } ],
    PAKKU_BAR      => [ 'bar',      { bool 'PAKKU_BAR',     $_ } ],
    PAKKU_SPINNER  => [ 'spinner',  { bool 'PAKKU_SPINNER', $_ } ],
    PAKKU_REFRESH  => [ 'refresh',  { bool 'PAKKU_REFRESH', $_ } ];

  for %general.sort -> ( :key($name), :value(( $key, &convert )) ) {
    %env<pakku>{ $key } = convert( %*ENV{ $name } ) if %*ENV{ $name }:exists;
  }

  # per command: PAKKU_<COMMAND>_<OPTION>, stored under the command (that is where fly() reads them)
  my %command =
    add      => %( to => { $_ }, deps => &deps, test => &bool.assuming( 'PAKKU_ADD_TEST' ), build => &bool.assuming( 'PAKKU_ADD_BUILD' ), serial => &bool.assuming( 'PAKKU_ADD_SERIAL' ), contained => &bool.assuming( 'PAKKU_ADD_CONTAINED' ), xtest => &bool.assuming( 'PAKKU_ADD_XTEST' ), precompile => &bool.assuming( 'PAKKU_ADD_PRECOMPILE' ), exclude => { .split( / \s+ / ).Array } ),
    update   => %( in => { $_ }, deps => &deps, test => &bool.assuming( 'PAKKU_UPDATE_TEST' ), build => &bool.assuming( 'PAKKU_UPDATE_BUILD' ), xtest => &bool.assuming( 'PAKKU_UPDATE_XTEST' ), clean => &bool.assuming( 'PAKKU_UPDATE_CLEAN' ), precompile => &bool.assuming( 'PAKKU_UPDATE_PRECOMPILE' ), exclude => { .split( / \s+ / ).Array } ),
    test     => %( build => &bool.assuming( 'PAKKU_TEST_BUILD' ), xtest => &bool.assuming( 'PAKKU_TEST_XTEST' ), timeout => &seconds.assuming( 'PAKKU_TEST_TIMEOUT' ) ),
    build    => %( timeout => &seconds.assuming( 'PAKKU_BUILD_TIMEOUT' ) ),
    remove   => %( from => { $_ } ),
    list     => %( repo => { $_ }, details => &bool.assuming( 'PAKKU_LIST_DETAILS' ) ),
    search   => %( count => { positive 'PAKKU_SEARCH_COUNT', $_ }, latest => &bool.assuming( 'PAKKU_SEARCH_LATEST' ), details => &bool.assuming( 'PAKKU_SEARCH_DETAILS' ), relaxed => &bool.assuming( 'PAKKU_SEARCH_RELAXED' ) ),
    state    => %( clean => &bool.assuming( 'PAKKU_STATE_CLEAN' ), updates => &bool.assuming( 'PAKKU_STATE_UPDATES' ) );

  for %command.sort -> ( :key($command), :value(%option) ) {
    for %option.sort -> ( :key($option), :value(&convert) ) {
      my $name = 'PAKKU_' ~ $command.uc ~ '_' ~ $option.uc;
      %env{ $command }{ $option } = convert( %*ENV{ $name } ) if %*ENV{ $name }:exists;
    }
  }

  %env;

}

