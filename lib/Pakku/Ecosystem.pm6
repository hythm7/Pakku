use JSON::Fast;
use LibCurl::HTTP :subs;

use X::Pakku;
use Pakku::Log;
use Pakku::Spec;
use Pakku::Dist;
use Pakku::Dist::Path;

unit class Pakku::Ecosystem;

has $!ecosystem;
has $.update;
has @.source;
has @!ignored;
has %!dist;

submethod TWEAK ( ) {

  @!ignored = < Test NativeCall nqp lib >;

  $!ecosystem = %?RESOURCES<ecosystem.json>.IO;
  self!update;

  🐛 "Eco: Loading ecosystem file [{@$!ecosystem}]";
  my @meta = flat from-json slurp $!ecosystem;

  race for @meta -> %meta {

    my $dist = Pakku::Dist.new: :%meta;

    %!dist{ $dist.name }.push: $dist;

  }


}

method recommend ( :@what!, :$deps! --> Seq ) {


  🐛 "Eco: Processing [{@what}]";

  @what.map( -> $what {

    my $dist = self.find: $what;

    $deps ?? self!get-deps: :$dist !! $dist.Seq;

  }).map( *.unique: :with( &[===] ) );

}


submethod !get-deps ( Pakku::Dist:D :$dist! ) {

  🐛 "Eco: Looking for deps of dist [$dist]";

  my @dist;

  my @dep = $dist.deps;

  🐛 "Eco: Found no deps for [$dist]" unless @dep;

  @dep .= map( -> $spec {

    if $spec.name ~~ any @!ignored {

      🐛 "Eco: Ignoring Core spec [$spec]";

      next;
    }


    🐛 "Eco: Found dep [$spec] for dist [$dist]";

    self.find: $spec;

  });

  for @dep -> $dist {

    @dist.append: self!get-deps( :$dist );

  }

  @dist.append: $dist;

  return @dist;

}

multi submethod find ( Pakku::Spec:D $spec ) {

  🐛 "Eco: Looking for spec [$spec]";

  my @cand;

  my $name = $spec.short-name;

  @cand = flat %!dist{$name} if so %!dist{$name};

  @cand = %!dist.values.grep( -> $dist { $name ~~ $dist.provides } ) unless @cand;

  @cand .= grep( * ~~ $spec );

  unless @cand {

    die X::Pakku::Ecosystem::NoCandy.new( :$spec );

    return;

  }

  🐛 "Eco: Found candies [{@cand}] matching [$spec]";

  my $candy = @cand.sort( { Version.new: .version } ).tail;


  🐛 "Eco: Recommending candy [$candy] for spec [$spec]";

  $candy;

}

multi submethod find ( IO::Path:D $path ) {

  Pakku::Dist::Path.new: $path;

}

method list-dists ( ) {
  # TODO: list per source

  %!dist.values;

}

method !update ( ) {


  return if $!update === False;

  my $mod-time = $!ecosystem.IO.modified.DateTime.minute - now.DateTime.minute;

  return if $!update === Any and $mod-time < 42;

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


