use Pakku::Dist::Perl6::Path;

unit class Pakku::Dist::Perl6::Inst;
  also is Pakku::Dist::Perl6;
  also does Distribution;



# Needed to implement Distribution role
# Required by .uninstall
#Stolen from Rakudo's InstalledDistribution
method content($address) {
  my $entry = $.meta<provides>.values.first: { $_{$address}:exists };
  my $file = $entry
    ?? $.prefix.add('sources').add($entry{$address}<file>)
    !! $.prefix.add('resources').add($.meta<files>{$address});

  $file.open(:r)
}
