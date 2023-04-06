use Pakku::Spec;

unit class Pakku::Meta;

has %.meta;

has Str $.dist   is built( False );
has Str $.id     is built( False );
has Str $.name   is built( False );

has $.source-location is built( False );

has %!deps;


method to-json  ( ) { Rakudo::Internals::JSON.to-json: %!meta }

multi method Str ( ::?CLASS:D: --> Str:D ) { $!dist }

multi method deps ( ) { %!deps }

multi method deps ( Bool:D :$deps where *.so ) {

  %!deps<build test runtime>.map( *.values.Slip ).map( *.Slip ).map( -> $spec { Pakku::Spec.new: $spec } );

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

  my $ver = %!meta<version> // %!meta<ver>;

  $!name = %!meta<name>;

  $!dist = quietly "{$!name}:ver<$ver>:auth<%!meta<auth>>:api<%!meta<api>>";

  $!id = nqp::sha1( $!dist );

  $!source-location = %!meta<source-location> // %!meta<source-url>;

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



proto method new ( | ) { * };

multi method new ( Str:D $json ) {

  my $meta = system-collapse Rakudo::Internals::JSON.from-json: $json;

  die 'Invalid json' unless $meta;

  samewith $meta;

}

multi method new ( IO::Path:D $path ) {

  my @meta = <META6.json META6.info META.json META.info>;

  my $meta-file = @meta.map( -> $file { $path.add: $file } ).first( *.f );

  die 'No META file' unless $meta-file;

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
        
        die "Unable to resolve path: {$path.cache[*-1].join('.')} in \$*DISTRO\nhad: {$value} ~~ {$value.WHAT.^name}"
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

my enum Color (

  RESET   =>  0,
  BLACK   => 30,
  RED     => 31,
  GREEN   => 32,
  YELLOW  => 33,
  BLUE    => 34,
  MAGENTA => 35,
  CYAN    => 36,
  WHITE   => 37,

);

my sub color ( Str:D $text, Color $color ) { "\e\[" ~ $color.Int ~ "m" ~ $text ~ "\e\[0m" }

multi method gist ( ::?CLASS:D: Bool:D :$details --> Str:D ) {

  return color( ~self, MAGENTA ) unless $details;
  
  (
    ( color( ~self, MAGENTA )                              ),
    ( gist-name $!name                                     ),
    ( gist-ver  %!meta<version>     if %!meta<version>     ),
    ( gist-auth %!meta<auth>        if %!meta<auth>        ),
    ( gist-api  %!meta<api>         if %!meta<api>         ),
    ( gist-desc %!meta<description> if %!meta<description> ),
    ( gist-url  %!meta<source-url>  if %!meta<source-url>  ),
    ( gist-deps %!deps              if %!deps              ),
    ( gist-prov %!meta<provides>    if %!meta<provides>    ),
    ( gist-file %!meta<files>       if %!meta<files>       ),
    (            ''                                        ),
  ).join( "\n" );


}

sub gist-name ( $name --> Str:D ) {

  color( 'name', BLUE     ) ~
  color( ' → ',  YELLOW ) ~
  color( ~$name, CYAN    )

}

sub gist-ver ( $ver --> Str:D ) {

  color( 'ver',  BLUE     ) ~
  color( '  → ', YELLOW ) ~
  color( ~$ver,  CYAN    )

}

sub gist-auth ( $auth --> Str:D ) {

  color( 'auth', BLUE     ) ~
  color( ' → ',  YELLOW ) ~
  color( ~$auth, CYAN    )

}

sub gist-api ( $api --> Str:D ) {

  color( 'api',  BLUE     ) ~
  color( '  → ', YELLOW ) ~
  color( ~$api,  CYAN    )

}

sub gist-desc ( $desc --> Str:D ) {

  color( 'desc', BLUE     ) ~
  color( ' → ',  YELLOW ) ~
  color( ~$desc, CYAN    )

}

sub gist-url ( $url --> Str:D ) {

  color( 'url',  BLUE     ) ~
  color( '  → ', YELLOW ) ~
  color( ~$url,  CYAN    )

}

sub gist-deps ( %deps --> Str:D ) {

  my $label = color( 'deps', BLUE );
  (
      "$label \n" ~
       %deps.kv.map( -> $phase, $need {
         color( '↳ ',        YELLOW )           ~
         color( ~$phase,     GREEN  ) ~ "\n"    ~
         color( '↳ ',        YELLOW ).indent(2) ~
         color( ~$need.keys, RED    ) ~ "\n"    ~
            $need.values.map( -> @spec  {
                @spec.map( -> $spec {
                  color( '↳ ',       YELLOW  )  ~
                  color( $spec.gist, MAGENTA )
                } ).join("\n").indent( 4 )

               } )
       }).join( "\n" ).indent( 5 )
  )

}

sub gist-prov ( %prov --> Str:D ) {

  my $label = color( 'prov', BLUE );

  (
    "$label \n" ~
     %prov.kv.map( -> $unit, $file {
       $file ~~ Hash
         ?? color( '↳ ',        YELLOW  )                      ~
            color( ~$unit,      MAGENTA ) ~ "\n"                    ~
            color( '↳ ',        YELLOW  ).indent( 2 )          ~
            color( ~$file.keys, CYAN    )  ~ "\n"               ~
              $file.kv.map( -> $file, $info {
                $info.grep( *.value ).hash.kv.map( -> $k, $v {
                  color( '↳ ',  YELLOW ).indent( 2 ) ~
                  color( ~$k,   RED    )             ~
                  color( ' → ', YELLOW )             ~
                  color( ~$v,   GREEN  )
                } ).join("\n").indent( 2 )
              })
         !! color( '↳ ',   YELLOW  )             ~
            color( ~$unit, MAGENTA ) ~ "\n"      ~
            color( '↳ ',   YELLOW  ).indent( 2 ) ~
            color( $file,  CYAN    );
     }).join( "\n" ).indent( 5 )
  )
}

sub gist-file ( %file --> Str:D ) {

  my $label = color( 'file', BLUE );

  (
    "$label \n" ~
     %file.kv.map( -> $name, $file {

       color( '↳ ',   YELLOW )             ~
       color( ~$name, CYAN   ) ~ "\n"      ~
       color( '↳ ',   YELLOW ).indent( 2 ) ~
         color( 'file', RED  )             ~
         color( ' → ',  YELLOW )           ~
         color( ~$file, GREEN  )
     }).join( "\n" ).indent( 5 )
  )

}
