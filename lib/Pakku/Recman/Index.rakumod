use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;
use Pakku::Util;

# The lookup engine shared by every recommendation manager: metas indexed by
# dist name and by provided unit; recommend picks the newest match, search
# matches names and units. Storage is the class's business.
unit role Pakku::Recman::Index;

has Str:D $.name is required;

method by-name     ( Str:D $name --> List ) { ... }
method by-provides ( Str:D $unit --> List ) { ... }
method names       ( --> List ) { ... }
method units       ( --> List ) { ... }

# normalise a META once; $source is what Core.fetch will download or copy
method normalise ( %raw, :$source! ) {

  my %meta = %raw;

  my $version = %meta<version> // %meta<ver>;

  without $version {
    log '🐛', header => 'REC', msg => ~( %meta<dist> // %meta<name> // '?' ), comment => "$!name: no version, skipped!";
    return Nil;
  }

  %meta<ver>    = ~$version;
  %meta<api>    = ~%meta<api> if %meta<api>.defined;    # fez has Int apis
  %meta<source> = $source;
  %meta<recman> = $!name;
  %meta<dist> //= "{ %meta<name> }:ver<{ %meta<ver> }>:auth<{ %meta<auth> // '' }>";

  %meta;

}

my sub identity ( %meta ) { %meta<name> ~ '|' ~ %meta<ver> ~ '|' ~ ( %meta<auth> // '' ) ~ '|' ~ ( %meta<api> // '' ) }

method lookup ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  my @candy = self.by-name( $spec.name ).grep( -> %meta { %meta ~~ $spec } );

  @candy = self.by-provides( $spec.name ).grep( -> %meta { %meta ~~ $spec } ) unless @candy;

  return Nil unless @candy;

  @candy.sort( &latest-first ).unique( as => &identity ).head;

}

# a hook for classes that can go and fetch a newer index when nothing matched
method refresh-on-miss ( Pakku::Spec::Raku:D :$spec! ) { Nil }

method recommend ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: recommending!";

  my $meta = self.lookup( :$spec ) // self.refresh-on-miss( :$spec );

  without $meta {
    log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: not found!";
    return Nil;
  }

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: found!";

  $meta;

}

method search (
  ::?CLASS:D:
  Pakku::Spec::Raku:D :$spec!,
  Bool:D :$relaxed = True,
  Bool:D :$latest  = False,
  Int:D  :$count   = 666,
) {

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: searching!";

  my $name  = $spec.name;
  my $rx    = $relaxed ?? rx:i/ "$name" / !! rx:i/ ^ "$name" $ /;
  my $exact = rx:i/ ^ "$name" $ /;

  my @hit;   # hashes are collected one by one: flat() would explode them into pairs

  for self.names.grep( $rx ) -> $name { @hit.push( $_ ) for self.by-name( $name )     }
  for self.units.grep( $rx ) -> $unit { @hit.push( $_ ) for self.by-provides( $unit ) }

  @hit = @hit.unique( as => &identity ).grep( -> %meta { %meta ~~ $spec } );

  unless @hit {
    log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: not found!";
    return Empty;
  }

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: found!";

  @hit .= sort( -> %a, %b {
    ( %b<name> ~~ $exact ).so cmp ( %a<name> ~~ $exact ).so   # exact name first
    || %a<name> cmp %b<name>
    || latest-first( %a, %b )
  } );

  @hit .= unique( as => { .<name> ~ ':' ~ ( .<auth> // '' ) } ) if $latest;

  @hit.head( $count );

}
