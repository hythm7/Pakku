use Pakku::Dist::Path;

unit class Pakku::Dist::Installed;
  also is Pakku::Dist;
  also does Distribution;



# Needed to implement Distribution role
# required .uninstall
# Stoledn from Rakudo's InstalledDistribution
method content($address) {
  my $entry = $.meta<provides>.values.first: { $_{$address}:exists };
  my $file = $entry
    ?? $.prefix.add('sources').add($entry{$address}<file>)
    !! $.prefix.add('resources').add($.meta<files>{$address});

  $file.open(:r)
}
