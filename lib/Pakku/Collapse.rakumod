use X::Pakku;

# S22 "System specific values": anywhere in the META, an object whose only key
# is by-<source>.<property> is replaced by the value for the running system.
#   by-env.FOO          -> %*ENV<FOO>, else the "" default
#   by-env-exists.FOO   -> "yes" / "no"
#   by-distro.name      -> $*DISTRO.name   (also kernel, raku, vm; legacy backend => vm, perl => raku)
# Version-valued properties match keys with a + (at least) or - (at most) suffix, most specific first.
unit module Pakku::Collapse;

sub collapse ( $data, Str:D :$dist = '?' ) is export {

  given $data {

    when Associative {

      my @by = .keys.grep( *.starts-with( 'by-' ) );

      return .map( { .key => collapse( .value, :$dist ) } ).Hash unless @by;

      die X::Pakku::Meta.new: msg => $dist, comment => "{ @by.join( ', ' ) }: a by-* key must be the only key of its object" if .keys > 1;

      collapse select( @by.head, .{ @by.head }, :$dist ), :$dist;

    }

    when Positional { .map( { collapse( $_, :$dist ) } ).Array }

    default { $data }

  }

}

my sub select ( Str:D $key, $switch, Str:D :$dist ) {

  die X::Pakku::Meta.new: msg => $dist, comment => "$key: value must be an object of alternatives" unless $switch ~~ Associative;

  my ( $source, $property ) = $key.substr( 3 ).split( '.', 2 );

  given $source {

    when 'env-exists' {
      my $which = %*ENV{ $property }:exists ?? 'yes' !! 'no';
      return $switch{ $which } if $switch{ $which }:exists;
      die X::Pakku::Meta.new: msg => $dist, comment => "$key: no '$which' alternative";
    }

    when 'env' {
      my $value = %*ENV{ $property };
      return $switch{ $value } if $value.defined and $switch{ $value }:exists;
      return $switch{ '' }     if $switch{ '' }:exists;
      die X::Pakku::Meta.new: msg => $dist, comment => "$key: no alternative for '{ $value // '' }' and no default";
    }

    when 'distro' | 'kernel' | 'raku' | 'vm' | 'backend' | 'perl' {

      my $value = do given $source {
        when 'distro'          { $*DISTRO }
        when 'kernel'          { $*KERNEL }
        when 'raku' | 'perl'   { $*RAKU   }
        when 'vm'   | 'backend' { $*VM    }
      }

      die X::Pakku::Meta.new: msg => $dist, comment => "$key: missing property" unless $property;

      for $property.split( '.' ) -> $method {
        die X::Pakku::Meta.new: msg => $dist, comment => "$key: no such property '$method'" unless $value.can( $method );
        $value = $value."$method"();
      }

      choose $value, $switch, :$key, :$dist;

    }

    default { die X::Pakku::Meta.new: msg => $dist, comment => "$key: unknown by-* source '$source'" }

  }

}

my sub choose ( $value, %switch, Str:D :$key, Str:D :$dist ) {

  if $value ~~ Version {

    my @candidate = %switch.keys.grep( * ne '' ).map( -> $k {
      my $suffix = $k.ends-with( '+' | '-' ) ?? $k.substr( *-1 ) !! '';
      %( :$k, :$suffix, v => Version.new( $suffix ?? $k.chop !! $k ) );
    } ).sort( { $^b<v> cmp $^a<v> } );

    for @candidate -> %c {
      my $order = %c<v> cmp $value;
      return %switch{ %c<k> } if %c<suffix> eq ''  and $order ~~ Same;
      return %switch{ %c<k> } if %c<suffix> eq '+' and $order ~~ Less | Same;
      return %switch{ %c<k> } if %c<suffix> eq '-' and $order ~~ More | Same;
    }

  } else {

    return %switch{ ~$value } if %switch{ ~$value }:exists;

  }

  return %switch{ '' } if %switch{ '' }:exists;

  die X::Pakku::Meta.new: msg => $dist, comment => "$key: no alternative for '$value' and no default";

}
