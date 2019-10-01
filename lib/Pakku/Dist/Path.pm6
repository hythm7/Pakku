use Pakku::Dist;

# BUG: handle dists having META6.info instead of META6.JSON

unit class Pakku::Dist::Path;
  also is Pakku::Dist;
  also is Distribution::Path;

method new ( $path ) {

  my @meta-files = < META6.json META.info >;

  my $meta-file = @meta-files.map( -> $file { $path.add: $file } ).first( *.f );

  nextwith $path, :$meta-file;

}
