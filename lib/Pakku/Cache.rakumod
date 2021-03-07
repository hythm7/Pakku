use Pakku::Spec;

unit class Pakku::Cache;

has IO $!cached is built;

method recommend ( Pakku::Spec:D :$spec! ) {

  my $spec-dir = $!cached.add: $spec.name;

  return Empty unless $spec-dir.d;

  dir $spec-dir
    ==> grep( *.IO.d )
    ==> map(  -> $dir   { try Pakku::Spec.new: $dir } )
    ==> grep( -> $candy { $candy ~~ $spec       } )
    ==> my @candy;

  return unless @candy;

  my $candy = @candy.reduce( &reduce-latest );

  $candy.prefix;

}

sub reduce-latest ( $left, $right ) {

  my %left  = $left.spec;
  my %right = $right.spec;

  return $left if Version.new( %left<api> // '' ) > Version.new( %right<api> // '' );
  return $left if Version.new( %left<ver> // '' ) > Version.new( %right<ver> // '' );
  return $right;

}

