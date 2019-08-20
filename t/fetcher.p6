#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Fetcher;

my $src = 'github.com/hythm/akku';

Pakku::Fetcher.fetch: :$src;
