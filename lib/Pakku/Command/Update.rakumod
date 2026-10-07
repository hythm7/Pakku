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

  my %state = self.state: :updates;

  my @add;

  for @want.sort.map( { Pakku::Spec.new: $_ } ) -> $spec {

    log '🐛', header => 'SPC', msg => ~$spec;

    my @candy = self!repo.map( { .candidates( $spec.dependency-specification ).Slip } ).grep( *.defined ).map( *.Str );

    unless @candy {
      log '🐞', header => 'SPC', msg => ~$spec, comment => 'not added!';
      next;
    }

    for @candy -> $dist {

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

    my @cln = self.state( :!updates ).values.grep( *.<cln> ).map( *.<meta>.Str );

    samewith 'remove', spec => @cln if @cln;

  }

}
