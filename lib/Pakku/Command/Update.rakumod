use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Update;

multi method fly (

         'update',
         :$deps       = True,
  Bool:D :$build      = True,
  Bool:D :$test       = True,
  Bool:D :$xtest      = False,
  Bool:D :$precompile = True,
  Bool:D :$clean      = True,
  Str:D  :$in         = 'site',
         :@exclude,
         :@spec,

  ) {

  my @want = @spec || self!installed;

  # the installed releases each spec names
  my @named = @want.sort.map( { Pakku::Spec.new: $_ } ).map( -> $spec {
    $spec => self!repo.map( { .candidates( $spec.dependency-specification ).Slip } ).grep( *.defined ).List
  } );

  # `pakku update Pakku` is about Pakku: only what the specs name is looked up, and cleaned after.
  # `pakku update` names everything that is added
  my %state = self.state: :updates, |( only => @named.map( *.value.map( *.Str ).Slip ).List if @spec );

  my @add;

  for @named -> ( :key( $spec ), :value( @candy ) ) {

    log '🐛', header => 'SPC', msg => ~$spec;

    unless @candy {
      log '🐞', header => 'SPC', msg => ~$spec, comment => 'not added!';
      next;
    }

    for @candy.map( *.Str ) -> $dist {

      my $state = %state{ $dist } or next;

      my @missing = $state.<dep>.grep( Pakku::Spec::Raku ).map( *.Str );

      log '🐞', header => 'DEP', msg => $_, comment => 'missing!' for @missing;

      @add.append: @missing;

      with $state.<upd>.head {
        log '🦋', header => 'UPD', msg => ~$_;
        @add.push: .Str;
      } else {
        log '🐛', header => 'UPD', msg => $dist, comment => 'no updates!';
      }

    }

  }

  if @add {

    log '🧚', header => 'UPD', msg => ~@add;

    my $repo = self!install-repo: $in, 'update';

    my @meta = self!resolve: @add.unique.map( { Pakku::Spec.new: $_ } ), :$deps, exclude => @exclude.map( { Pakku::Spec.new: $_ } );

    my @dist = self!fetch-dists: @meta;

    self!stage-dists: @dist, :$repo, :$build, :$test, :$xtest, :$precompile;

  }

  if $clean and not self!dont {

    my @name = @named.map( *.value.map( *.meta<name> ).Slip ).unique;

    my @cln = self.state( :!updates ).values.grep( *.<cln> ).map( *.<meta> ).grep( { not @spec or .name eq any @name } ).map( *.Str );

    samewith 'remove', spec => @cln, :exact if @cln;

  }

}
