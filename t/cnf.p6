#!/usr/bin/env perl6
#
use lib 'lib';

use Pakku::Grammar::Cnf;

my $config = 'cnf/cnf'.IO;

my $parser  = Pakku::Grammar::Cnf;
my $actions = Pakku::Grammar::Cnf::Actions;
my $cnf     = $parser.parsefile( $config, :$actions, :rule<TOP> );

say $cnf.ast;


