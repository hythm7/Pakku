use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Add;

multi method fly (

         'add',
         :@spec!,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$serial     = False,
  Bool:D :$contained  = False,
  Str:D  :$to         = 'site',
         :@exclude,

) {

  log '🧚', header => 'ADD', msg => ~@spec;

  my $repo = self!install-repo: $to, ~@spec;

  my @repo = self!where-to-look: $repo, :$contained;

  my @top = @spec
    .map( { Pakku::Spec.new: $_ } )
    .unique( as => *.Str )
    .grep( -> $spec { self!force or not self.satisfied( :$spec, :@repo ) } );

  unless @top {
    log '🧚', header => 'ADD', msg => ~@spec, comment => 'already added!';
    return;
  }

  my @meta = self!resolve: @top, :$deps, :$contained, exclude => @exclude.map( { Pakku::Spec.new: $_ } );

  unless @meta {
    log '🧚', header => 'ADD', msg => ~@spec, comment => 'nothing to add!';
    return;
  }

  my @dist = self!fetch-dists: @meta;

  self!stage-dists: @dist, :$repo, :$serial, :$build, :$test, :$xtest, :$precompile;

}

multi method fly (

         'add',
  IO:D   :$path! is copy,
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$serial     = False,
  Bool:D :$contained  = False,
  Str:D  :$to         = 'site',
         :@exclude,

) {

  log '🧚', header => 'ADD', msg => ~$path;

  $path = self!dist-path: $path;   # a tarball or a .git directory becomes a dist directory

  my $repo = self!install-repo: $to, ~$path;

  my @repo = self!where-to-look: $repo, :$contained;

  my $spec = Pakku::Spec.new: $path;

  if not self!force and self.satisfied( :$spec, :@repo ) {
    log '🧚', header => 'ADD', msg => ~$spec, comment => 'already added!';
    return;
  }

  my $meta = Pakku::Meta.new: $path;

  self!check-provides: $meta, $path;

  my @meta = self!resolve: $meta.deps( :$deps ), :$deps, :$contained, exclude => @exclude.map( { Pakku::Spec.new: $_ } );

  my @dist = self!fetch-dists: @meta;

  @dist.push: $meta.to-dist( $path ) unless $deps ~~ 'only';

  self!stage-dists: @dist, :$repo, :$serial, :$build, :$test, :$xtest, :$precompile;

}

# where "already added" is decided: the whole chain, or only the target repo for a contained
# add and for a repo outside the chain (D10)
method !where-to-look ( $repo, Bool:D :$contained ) {

  return [ $repo ] if $contained;
  return [ $repo ] unless self!repo.first( *.prefix eq $repo.prefix );

  self!repo;

}

# issue #36: a module file under lib/ that is not in provides is invisible to the loader
method !check-provides ( Pakku::Meta:D $meta, IO::Path:D $path ) {

  my $lib = $path.add( 'lib' );

  return unless $lib.d;

  my @provided = ( $meta.meta<provides> // {} ).values.map( { $_ ~~ Associative ?? .<file> !! $_ } ).map( *.subst( '\\', '/', :g ) );

  for Rakudo::Internals.DIR-RECURSE( ~$lib, file => *.ends-with( any <.rakumod .pm6 .pm> ) ).sort -> $file {

    my $rel = $file.IO.relative( $path ).subst( '\\', '/', :g );

    log '🐞', header => 'MTA', msg => $rel, comment => 'not in provides!' unless $rel eq any @provided;

  }

}

# a tarball by URL, or a git repository: fetched, then added like a path
multi method fly ( 'add', Str:D :$url!, *%opt ) {

  log '🧚', header => 'ADD', msg => $url;

  samewith 'add', path => self!fetch-path( $url ), |%opt;

}
