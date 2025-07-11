use Pakku::Log;
use Pakku::Meta;

unit class Pakku::Recman::Local;

has $.name;
has $!location;

has %!meta;

has %!provides;

method recommend ( ::?CLASS:D: :$spec! ) {

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: recommending!";

  my $name   = $spec.name;

  my @candy;

  @candy = flat %!meta{ $name  } if %!meta{ $name }:exists;

  @candy .= grep( -> %candy { %candy ~~ $spec } );

  unless @candy {

    @candy = flat %!provides{ $name } if %!provides{ $name }:exists;

    @candy .= grep( -> %candy {  %candy ~~ $spec } );

  }

  return unless @candy;

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: found!", :msg-delimit;

  @candy.reduce( &reduce-latest );

}

method search (

    ::?CLASS:D:
    :$spec!,
    :$relaxed!,
    :$count!,

  ) {

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: searching!", :msg-delimit;

  my $pattern = $spec.name.raku;

  $pattern = "^ $pattern \$" unless $relaxed;

  my $rx   = rx/ :i <$pattern> /;

  my @candy;

  @candy = flat %!meta{ $rx  } if %!meta{ $rx }:exists;

  @candy.append:  flat %!provides{ $rx } if %!provides{ $rx }:exists;
  @candy .= unique;

  @candy .= grep( -> %candy {  %candy ~~ $spec } );

  unless @candy {

    log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: not found!";

    return;
  }

  log '🐛', header => 'REC', msg => ~$spec, comment => "$!name: found!";

  @candy
    ==> sort( -> %left, %right {
      quietly (%right<name> ~~ $rx ) cmp (%left<name> ~~ $rx ) ||
      quietly (%right<name> ~~ $rx ) cmp (%left<name> ~~ $rx ) ||
      %left<name> cmp %right<name>                                                   ||
      quietly ( Version.new( %right<ver> ) cmp Version.new( %left<ver> ) ) or
      quietly ( Version.new( %right<api> ) cmp Version.new( %left<api> ) );
    })
    ==> head( $count );

}

submethod BUILD ( Str:D :$!name!, IO::Path:D() :$!location! ) {

  unless $!location.d {

    log '🐞', header => 'REC', msg => ~$!name, comment => "$!location: does not exist!" unless $!location.d;

    return;
  }

  eager dir $!location
    ==> grep( *.d )
    ==> map( -> $dir {

      unless $dir.add( 'META6.json' ).f {

        log '🐞', header => 'REC', msg => ~$!name, comment => "$dir: no META6.json!";

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

multi reduce-latest ( %left ) { %left }

multi reduce-latest ( %left, %right ) {

  return %left if         Version.new( %left<ver> ) > Version.new( %right<ver> );
  return %left if quietly Version.new( %left<api> ) > Version.new( %right<api> );

  %right;

}

