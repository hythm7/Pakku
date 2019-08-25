#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Distribution::Path;

my $d = Pakku::Distribution::Path.new: '../Grid'.IO;

say $d.license;

