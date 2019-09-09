use Pakku::Dist;

unit class Pakku::Dist::Installed;
  also is Pakku::Dist;

  has $.repo;

submethod BUILD ( :$prefix ) {

  $!repo = $prefix.basename;

}


multi method provides ( ) {

  my %provides =  self.meta<provides>;

  %provides;

}
