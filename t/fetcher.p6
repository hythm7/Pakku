#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Fetcher;

my $src = '/home/helganin/dev/Pakku';

Pakku::Fetcher.fetch: :$src;
