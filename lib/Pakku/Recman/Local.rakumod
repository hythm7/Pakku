use Pakku::Log;
use Pakku::Meta;

unit class Pakku::Recman::Local;

has $.name;
has $!location;

has %!meta;

has %!provides;

method recommend ( ::?CLASS:D: :$spec! ) {

  🐛 qq[REC: ｢$!name｣ ‹$spec› recommending...];

  my $name   = $spec.name;
  my $nameid = nameid( $name );

  my @candy;

  @candy = flat %!meta{ $nameid  } if %!meta{ $nameid }:exists;

  @candy .= grep( -> %candy { %candy ~~ $spec } );

  unless @candy {

    @candy = flat %!meta{ %!provides{ $nameid } } if %!provides{ $nameid }:exists;

    @candy .= grep( -> %candy {  %candy ~~ $spec } );

  }


  unless @candy {

    🐛 qq[REC: ｢$!name｣ ‹$spec› not found!];

    return;
  }

  @candy.reduce( &reduce-latest );

}

method search ( ::?CLASS:D: :$spec!, :$count = ∞ ) {

  🐛 qq[REC: ｢$!name｣ ‹$spec› searching...];

  my %meta;
  my %provides;

  %!meta.values
    ==> map( *.Slip )
    ==> map( -> $meta {

      my $name   = $meta<name>.lc;
      my $nameid = nameid( $name );

      %meta{ $nameid }.push: $meta;

      for $meta<provides>.keys -> $unit {
        %provides{ nameid( $unit.lc ) } = $nameid
      }

    });

  my $name   = $spec.name.lc;
  my $nameid = nameid( $name );

  my @candy;

  @candy = flat %meta{ $nameid  } if %meta{ $nameid }:exists;

  @candy = flat %meta{ %provides{ $nameid } } if %provides{ $nameid }:exists;

  @candy .= grep( -> %candy {  %candy ~~ $spec } );

  unless @candy {

    🐛 qq[REC: ｢$!name｣ ‹$spec› not found!];

    return;
  }

  @candy.head: $count;

}

submethod BUILD ( Str:D :$!name!, IO::Path:D() :$!location! ) {

  use nqp;

  unless $!location.d {

    🐞 qq[REC: ｢$!name｣ ‹$!location› does not exist] unless $!location.d; 
    return;
  }

  eager dir $!location
    ==> grep( *.d )
    ==> map( -> $dir {

      unless $dir.add( 'META6.json' ).f {

        🐞 qq[REC: ｢$!name｣ ‹$dir› no META6.json!]; 

        next;
      }

      my $meta = Pakku::Meta.new: $dir;

      my $nameid = nameid( $meta.name );

      my %meta = $meta.meta;

      %meta<source> = $dir;

      %!meta{ $nameid }.push: %meta;

      for %meta<provides>.keys -> $unit {
        %!provides{ nameid( $unit ) } = $nameid
      }

    } );

}

my sub reduce-latest ( %left, %right ) {

  return %left if         Version.new( %left<ver> ) > Version.new( %right<ver> );
  return %left if quietly Version.new( %left<api> ) > Version.new( %right<api> );
  return %right;

}

my sub nameid ( Str:D $name ) { use nqp; nqp::sha1( $name ) }
