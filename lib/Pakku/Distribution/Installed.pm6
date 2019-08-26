use Pakku::Distribution;

unit class Pakku::Distribution::Installed;
  also is Pakku::Distribution;


multi method provides ( ) {

  my %provides =  self.meta<provides>;

}
