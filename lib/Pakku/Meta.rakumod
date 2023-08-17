use Pakku::Log;
use Pakku::Spec;

unit class Pakku::Meta;

has %.meta;

has Str $.dist   is built( False );
has Str $.id     is built( False );
has Str $.name   is built( False );

has $.source is built( False );

has %!deps;


method to-json  ( ) { Rakudo::Internals::JSON.to-json: %!meta }

multi method Str ( ::?CLASS:D: --> Str:D ) { $!dist }

multi method deps ( ) { %!deps }

multi method deps ( Bool:D :$deps where *.so ) {

  %!deps<build test runtime>.map( *.values.Slip ).map( *.Slip ).unique.map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'runtime' ) {

  %!deps<runtime>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'test' ) {

  %!deps<test>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'build' ) {

  %!deps<build>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

}

multi method deps ( Str:D :$deps where 'only' ) { samewith :deps }

multi method deps ( Bool:D :$deps where not *.so ) { Empty }


method to-dist ( ::?CLASS:D: IO::Path:D $prefix! ) {

  # %bins and resources stolen from Rakudo
  my %bins = Rakudo::Internals.DIR-RECURSE($prefix.add('bin').absolute).map(*.IO).map: -> $real-path {
    my $name-path = $real-path.is-relative
      ?? $real-path
      !! $real-path.relative($prefix);
    $name-path.subst(:g, '\\', '/') => $name-path.subst(:g, '\\', '/')
  }

  my $resources-dir = $prefix.add('resources');
  my %resources = %!meta<resources>.grep(*.?chars).map(*.IO).map: -> $path {
    my $real-path = $path ~~ m/^libraries\/(.*)/
        ?? $resources-dir.add('libraries').add( $*VM.platform-library-name($0.Str.IO) )
        !! $resources-dir.add($path);
    my $name-path = $path.is-relative
        ?? "resources/{$path}"
        !! "resources/{$path.relative($prefix)}";
    $name-path.subst(:g, '\\', '/') => $real-path.relative($prefix).subst(:g, '\\', '/')
  }

  %!meta<files> = Hash.new(%bins, %resources);

  self does Distribution::Locally( :$prefix );

}

submethod TWEAK ( ) {

  use nqp;

  $!name = %!meta<name>;

  my $ver = %!meta<version> // %!meta<ver>;

  $!dist = quietly "{$!name}:ver<$ver>:auth<%!meta<auth>>:api<%!meta<api>>";

  $!id = nqp::sha1( $!dist );

  $!source = %!meta<source>;

  %!deps<build><requires>.append: flat %!meta<build-depends> if %!meta<build-depends>;
  %!deps<test><requires>.append:  flat %!meta<test-depends>  if %!meta<test-depends>;

  given %!meta<depends> {

    when Positional {

      %!deps<runtime><requires>.append: flat %!meta<depends> if %!meta<depends>;

    }

    when Associative {

      %!deps<runtime><requires>.append:   flat .<runtime>             if .<runtime> ~~ Positional;
      %!deps<test><requires>.append:      flat .<test>                if .<test>    ~~ Positional;
      %!deps<build><requires>.append:     flat .<build>               if .<build>   ~~ Positional;

      %!deps<runtime><requires>.append:   flat  .<runtime><requires>  if .<runtime><requires>;
      %!deps<runtime><recommends>.append: flat .<runtime><recommends> if .<runtime><recommends>;
      %!deps<runtime><suggests>.append:   flat  .<runtime><suggests>  if .<runtime><suggests>;

      %!deps<test><requires>.append:      flat   .<test><requires>    if .<test><requires>;
      %!deps<test><recommends>.append:    flat   .<test><recommends>  if .<test><recommends>;
      %!deps<test><suggests>.append:      flat   .<test><suggests>    if .<test><suggests>;

      %!deps<build><requires>.append:     flat   .<build><requires>   if .<build><requires>;
      %!deps<build><recommends>.append:   flat   .<build><recommends> if .<build><recommends>;
      %!deps<build><suggests>.append:     flat   .<build><suggests>   if .<build><suggests>;
    }

  }

}

multi method gist ( ::?CLASS:D: Bool:D :$details --> Str:D ) {


  return  color("｢{self}｣" , magenta ) unless $details;
  
  my Str $info = color("MTA: ｢{self}｣" , magenta );

  $info ~= .map( -> $dep { color( "\nDEP: ｢$dep｣", cyan ) } ) with self.deps( :deps ).sort;

  $info ~= .map( -> $provide { color( "\nPRV: ｢$provide｣", green )} ) with %!meta<provides>.keys.sort;

  $info ~= color("\nURL: ｢{.Str}｣", blue  ) with %!meta<source-url>;
  $info ~= color("\nDES: ｢{.Str}｣", white ) with %!meta<description>;

  $info;

}


proto method new ( | ) { * };

multi method new ( Str:D $json ) {

  my $meta = system-collapse Rakudo::Internals::JSON.from-json: $json;

  die 'Invalid json' unless $meta;

  samewith $meta;

}

multi method new ( IO::Path:D $path ) {

  my $meta-file = $path.add: 'META6.json';

  die "No META file found in $path" unless $meta-file.e;

  my $meta = Rakudo::Internals::JSON.from-json: $meta-file.slurp;

  samewith $meta;

}

multi method new ( %meta ) {

  self.bless: meta => system-collapse %meta;

}

### borrowed from System::Query:ver<0.1.6>:auth<zef:tony-o>
### to avoid adding a dependency

sub follower(@path, $idx, $PTR) {
  die "Attempting to find \$*{@path[0].uc}.{@path[1..*].join('.')}"
    if !$PTR.^can("{@path[$idx]}") && $idx < @path.elems;
  return $PTR."{@path[$idx]}"()
    if $idx+1 == @path.elems;
  return follower(@path, $idx+1, $PTR."{@path[$idx]}"());   
}

sub system-collapse($data) {
  return $data 
    if $data !~~ Hash && $data !~~ Array;
  my $return = $data.WHAT.new;
  for $data.keys -> $idx {
    given $idx {
      when /^'by-env-exists'/ {
        my $key = $idx.split('.')[1];
        my $value = %*ENV{$key}:exists ?? 'yes' !! 'no';
        return system-collapse($data{$idx}{$value}) if $data{$idx}{$value}:exists;
        die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value}";
      }
      when /^'by-env'/ {
        my $key = $idx.split('.')[1];
        my $value = %*ENV{$key};
        return system-collapse($data{$idx}{$value}) if defined $value and $data{$idx}{$value}:exists;
        die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value // ''}";
      }
      when /^'by-' (['distro'|'kernel'|'backend'])/ {
        my $PTR = $/[0] eq 'distro'
          ?? $*DISTRO
          !! $/[0] eq 'kernel'
            ?? $*KERNEL
            !!  $*BACKEND;

        my $path  = $idx.split('.');
        my $value = follower($path, 1, $PTR);
        my $fkey;

        if $value ~~ Version {
          my @checks = $data{$idx}.keys.map({ 
            my $suff = $_.substr(*-1);
            %(
              version  => Version.new($suff eq qw<+ ->.any ?? $_.substr(0, *-1) !! $_),
              orig-key => $_,
              ($suff eq qw<+ ->.any ?? suffix  => $suff !! ()),
            )
          }).sort({ $^b<version> cmp $^a<version> });
          for @checks -> $version {
            next unless
              $version<version> cmp $value ~~ Same ||
              ($version<version> cmp $value ~~ Less && $version<suffix> eq '+') ||
              ($version<version> cmp $value ~~ More && $version<suffix> eq '-');
            $fkey = $version<orig-key>;
            last;
          }
        } else { 
          $fkey  = ($data{$idx}{$value}:exists) ?? 
                     $value !!
                     ($data{$idx}{''}:exists) ??
                       '' !!
                       Any;
        }
        
        die "Unable to resolve path: {$path.cache[*-1].join('.')} in $idx\nhad: {$value} ~~ {$value.WHAT.^name}"
          if Any ~~ $fkey;
        return system-collapse($data{$idx}{$fkey});
      }
      default {
        my $val = system-collapse($data ~~ Array ?? $data[$idx] !! $data{$idx});
        $return{$idx} = $val
          if $return ~~ Hash;
        $return.push($val)
          if $return ~~ Array;

      }
    };
  }
  return $return;
}


