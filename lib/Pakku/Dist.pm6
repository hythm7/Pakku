unit class Pakku::Dist;
  also does Distribution;

method meta(--> Hash:D) {
  $.meta;
}

method content($name-path --> IO::Handle:D) {
  $.content;
}
