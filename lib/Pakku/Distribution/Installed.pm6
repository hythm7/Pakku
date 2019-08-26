use Pakku::Distribution;

unit class Pakku::Distribution::Installed;
  also is Pakku::Distribution;

  has $.repo;

submethod BUILD ( :$prefix ) {

  $!repo = $prefix.basename;

}


multi method provides ( ) {

  my %provides =  self.meta<provides>;

  %provides;

}
