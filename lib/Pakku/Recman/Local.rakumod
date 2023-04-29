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

  my @candy;

  @candy = flat %!meta{ $name  } if %!meta{ $name }:exists;

  @candy .= grep( -> %candy { %candy ~~ $spec } );

  unless @candy {

    @candy = flat %!provides{ $name } if %!provides{ $name }:exists;

    @candy .= grep( -> %candy {  %candy ~~ $spec } );

  }

  return unless @candy;

  @candy.reduce( &reduce-latest );

}

method search ( ::?CLASS:D: :$spec!, :$count! ) {

  🐛 qq[REC: ｢$!name｣ ‹$spec› searching...];

  my $name = $spec.name;

  my $rx   = rx/ :i $name /;

  my @candy;

  @candy = flat %!meta{ $rx  } if %!meta{ $rx }:exists;

  @candy.append:  flat %!provides{ $rx } if %!provides{ $rx }:exists;
  @candy .= unique;

  @candy .= grep( -> %candy {  %candy ~~ $spec } );

  unless @candy {

    🐛 qq[REC: ｢$!name｣ ‹$spec› not found!];

    return;
  }

  @candy
    ==> sort( -> %left, %right {
      quietly (%right<name> ~~ / :i ^ $name / ) cmp (%left<name> ~~ / :i ^ $name / ) ||
      quietly (%right<name> ~~ / :i   $name / ) cmp (%left<name> ~~ / :i   $name / ) ||
      %left<name> cmp %right<name>                                                   ||
      quietly ( Version.new( %right<ver> ) cmp Version.new( %left<ver> ) ) or
      quietly ( Version.new( %right<api> ) cmp Version.new( %left<api> ) );
    })
    ==> head( $count );

}

submethod BUILD ( Str:D :$!name!, IO::Path:D() :$!location! ) {

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

      my $name = $meta.name;
      my %meta = $meta.meta;

      %meta<source> = $dir;

      %!meta{ $name }.push: %meta;

      for %meta<provides>.keys -> $unit {
        %!provides{ $unit }.push: %meta;
      }

    } );

  my role LookupRegex {

    has Str @!key = self.keys;

    multi method EXISTS-KEY( Regex:D $rx ) {

      so @!key.first( -> $key { $key ~~ $rx } );

    }

    multi method AT-KEY( Regex:D $rx ) {

      my @key = @!key.grep( -> $key { $key ~~ $rx } );

      return Any unless @key;

      @key.map( -> $key { flat samewith $key } );

    }
    
  }


  %!meta     does LookupRegex;
  %!provides does LookupRegex;

}

my sub reduce-latest ( %left, %right ) {

  return %left if         Version.new( %left<ver> ) > Version.new( %right<ver> );
  return %left if quietly Version.new( %left<api> ) > Version.new( %right<api> );
  return %right;

}

