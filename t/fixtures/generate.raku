#!/usr/bin/env raku
# Regenerates t/fixtures/mirror/*.tar.gz and t/fixtures/index.json from t/fixtures/dists.
# Dev-time tool only (needs a `tar` binary); the generated files are committed.
my $here   = $*PROGRAM.parent;
my $dists  = $here.add('dists');
my $mirror = $here.add('mirror');
$mirror.mkdir;

# tarball root layouts seen in the wild: fez uses dist/, REA archives are root-level or <repo>-master/
my %root = 'Baz-1.0' => '', 'Qux-2.0' => 'Qux-master';

my @index;
for $dists.dir.grep(*.d).sort -> $dir {
  my %meta = Rakudo::Internals::JSON.from-json: $dir.add('META6.json').slurp;
  my $root = %root{ $dir.basename } // 'dist';
  my $tmp  = $*TMPDIR.add("pakku-fixture-{ $*PID }");
  run 'rm', '-rf', $tmp; $tmp.mkdir;
  my $src = $root ?? $tmp.add($root) !! $tmp;
  $root ?? run('cp', '-r', $dir, $src) !! run('cp', '-r', "$dir/.", $tmp);
  my $tar = $mirror.add("{ $dir.basename }.tar.gz");
  run 'tar', '-C', $tmp, '-czf', $tar, |( $root ?? ($root,) !! $tmp.dir.map(*.basename) );
  run 'rm', '-rf', $tmp;
  %meta<path> = "mirror/{ $dir.basename }.tar.gz";
  %meta<dist> = "{ %meta<name> }:ver<{ %meta<version> }>:auth<{ %meta<auth> // '' }>";
  @index.push: %meta;
  @index.push: %meta if $dir.basename eq 'Foo-0.2';   # a verbatim duplicate, as the real fez index has
  say "{ $tar.basename } <- { $dir.basename } (root '{ $root || '.' }')";
}
$here.add('index.json').spurt: Rakudo::Internals::JSON.to-json(@index, :pretty, :sorted-keys);
say "index.json: { +@index } entries";
