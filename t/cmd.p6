#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Grammar::Cmd;

my $parser  = Pakku::Grammar::Cmd;
my $actions = Pakku::Grammar::Cmd::Actions;
my $cmd = $parser.parse( @*ARGS, :$actions, :rule<TOP> );

say $cmd.ast with $cmd;


