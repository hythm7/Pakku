#!/usr/bin/env raku

use Pakku::Archive;

my $archive = 'e660e2bdd840a3432451a948bdabb9d7dbf7e451.tar.gz';

my $dest = '/tmp/archive/';

extract :$archive :$dest;


