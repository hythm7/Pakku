#!/usr/bin/env raku

use lib $*PROGRAM.resolve.parent( 2 ) ~ '/lib';

use Pakku;

Pakku.new.fun;
