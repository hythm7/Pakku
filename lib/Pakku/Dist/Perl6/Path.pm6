use Pakku::Dist::Perl6;

unit class Pakku::Dist::Perl6::Path;
  also is Pakku::Dist::Perl6;
  also is Distribution::Path;

method new ( $path ) {

  my @meta-files = < META6.json META.info >;

  my $meta-file = @meta-files.map( -> $file { $path.add: $file } ).first( *.f );

  die X::Pakku::Dist::Perl6::Path::NoMeta.new: :$path unless $meta-file;

  nextwith $path, :$meta-file;

}
