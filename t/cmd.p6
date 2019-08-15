#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Grammar::CMD;

my $parser  = Pakku::Grammar::CMD;
my $actions = Pakku::Grammar::CMD::Actions;
my $cmd = $parser.parse( @*ARGS, :$actions, :rule<TOP> );

say $cmd.ast with $cmd;


