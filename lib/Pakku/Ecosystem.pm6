use JSON::Fast;
use LibCurl::HTTP :subs;

use X::Pakku;
use Pakku::Log;
use Pakku::DepSpec;
use Pakku::Dist;
use Pakku::Dist::Perl6::Path;
use Pakku::Dist::Bin;

unit class Pakku::Ecosystem;

has $!ecosystem;
has $.update;
has @.source;
has @!ignored;
has %!dist;
has @!dist;

# TODO: deps only
method recommend ( :@what!, :$deps --> Seq ) {

  🐛 "Eco: Processing [{@what}]";

  my %deps;

  given $deps {

    when 'requires' {
      %deps.push: ( :requires );
      %deps.push: ( :!recommends );
    }

    when 'recommends' {
      %deps.push: ( :requires );
      %deps.push: ( :recommends );
    }

    when 'only' {
      %deps.push: ( :only );
    }

  }


  @what.map( -> $what {

    my $dist = self.find: $what;

    if %deps {

      my @dist = self!get-deps: :$dist, |%deps;

      @dist.pop if %deps<only>;

      @dist

    }

    else {

      $dist.Seq;

    }

  }).map( *.unique: :with( &[===] ) );

}


submethod !get-deps (

  Pakku::Dist:D :$dist!,
  Bool:D        :$only         = False,
  Bool:D        :$requires     = True,
  Bool:D        :$recommends   = True,
  Bool:D        :$runtime      = True,
  Bool:D        :$test         = True,
  Bool:D        :$build        = True,
) {

  🐛 "Eco: Looking for deps of dist [$dist]";

  my @dist;

  my @dep = $dist.deps: :$runtime, :$test, :$build, :$requires, :$recommends;

  🐛 "Eco: Found no deps for [$dist]" unless @dep;

  @dep .= map( -> $depspec {

    if $depspec.short-name ~~ any @!ignored {

      🐛 "Eco: Ignoring Core spec [$depspec]";

      next;
    }


    🐛 "Eco: Found dep [$depspec] for dist [$dist]";

    self.find: $depspec;

  });

  for @dep -> $dist {

    @dist.append: self!get-deps( :$dist );

  }

  @dist.append: $dist;

  return @dist;

}

multi submethod find ( Pakku::DepSpec::Perl6:D $depspec ) {

  🐛 "Eco: Looking for spec [$depspec]";

  my @cand;

  my $name = $depspec.short-name;

  @cand = flat %!dist{$name} if so %!dist{$name};

  @cand = @!dist.grep( -> $dist { $name ~~ $dist.provides } ) unless @cand;

  @cand .= grep( * ~~ $depspec );

  unless @cand {

    die X::Pakku::Ecosystem::NoCandy.new( :$depspec );

    return;

  }

  🐛 "Eco: Found candies [{@cand}] matching [$depspec]";

  my $candy = @cand.sort( { Version.new: .ver } ).tail;


  🐛 "Eco: Recommending candy [$candy] for spec [$depspec]";

  $candy;

}

multi submethod find ( Pakku::DepSpec::Bin:D $spec ) {

  Pakku::Dist::Bin.new: name => $spec.short-name;

}

multi submethod find ( IO::Path:D $path ) {

  Pakku::Dist::Perl6::Path.new: $path;

}

method list-dists ( ) {

  @!dist;

}

method !update ( ) {

  return if $!update === False;

  my $mod-time = now - $!ecosystem.IO.modified;

  return if $!update === Any and $mod-time < 2520;

  🐛 "Eco: Updating Ecosystem";

  my @meta;

  race for @!source -> $source {

    🐛 "Eco: Getting source [$source]";
    @meta.append: flat jget $source;

  }

  given open $!ecosystem, :w {
    🐛 "Eco: Writing Ecosystem to file [$!ecosystem]";
    .say( to-json @meta );
    .close;
  }
}

submethod TWEAK ( ) {

  @!ignored = < Test NativeCall nqp lib >;

  $!ecosystem = %?RESOURCES<ecosystem.json>.IO;

  self!update;

  🐛 "Eco: Loading ecosystem file [{$!ecosystem}]";
  my @meta = flat from-json slurp $!ecosystem;

  for @meta -> %meta {

    my $dist = Pakku::Dist::Perl6.new: :%meta;

    %!dist{ $dist.name }.push: $dist;
    @!dist.push: $dist;

  }

}


