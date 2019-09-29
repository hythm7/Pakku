#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Dist::Path;

my $d = Pakku::Dist::Path.new: '../Grid'.IO;

say $d.license;

