use Pakku::Dist;

unit class Pakku::Dist::Installed;
  also is Pakku::Dist;


multi method provides ( ) {

  my %provides =  self.meta<provides>;

  %provides;

}
