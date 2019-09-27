#!/usr/bin/env perl6
#
use Test;
use lib 'lib';
use Pakku::Grammar::Cmd;

my @tests = (
# [ 'string to test', 'method', 'message' ]
  [ '',                          'help',   'help'                       ],
  [ 'add Spec',                  'add',    'add [Spec]'                 ],
  [ 'add deps',                  'add',    'add [deps]'                 ],
  [ 'add deps Spec',             'add',    'add deps [Spec]'            ],
  [ 'add build Spec',            'add',    'add build [Spec]'           ],
  [ 'add test Spec',             'add',    'add test [Spec]'            ],
  [ 'add force Spec',            'add',    'add force [Spec]'           ],
  [ 'add nodeps Spec',           'add',    'add nodeps [Spec]'          ],
  [ 'add nobuild Spec',          'add',    'add nobuild [Spec]'         ],
  [ 'add notest Spec',           'add',    'add notest [Spec]'          ],
  [ 'add Spec1 Spec2',           'add',    'add [Spec1 Spec2]'          ],
  [ 'add noforce Spec',          'add',    'add noforce [Spec]'         ],
  [ 'add into home Spec',        'add',    'add into home [Spec]'       ],
  [ 'add into notrepo Spec',     'add',    'add [into notrepo Spec]'    ],
  [ 'remove Spec1 Spec2',        'remove', 'remove [Spec1 Spec2]'       ],
  [ 'remove from home Spec',     'remove', 'remove from repo [Spec]'    ],
  [ 'list',                      'list',   'list'                       ],
  [ 'list local',                'list',   'list local'                 ],
  [ 'list remote',               'list',   'list remote'                ],
  [ 'list local Spec',           'list',   'list local [Spec]'          ],
  [ 'list remote Spec1 Spec2',   'list',   'list remote [Spec1 Spec2]'  ],
  [ 'list local details',        'list',   'list local details'         ],
  [ 'list remote details Spec',  'list',   'list remote details [Spec]' ],
  [ 'list remote details Spec',  'list',   'list remote details [Spec]' ],
  [ 'list Spec',                 'list',   'list [Spec]'                ],
  [ 'help',                      'help',   'help'                       ],
  [ 'add',                       'help',   'help add'                   ],
  [ 'help add',                  'help',   'help add'                   ],
  [ 'notcmd',                    'help',   'help'                       ],
  [ 'help notcmd',               'help',   'help'                       ],
);

plan 30;

for @tests -> [ $string, $method, $msg ] {

  my $parser  = Pakku::Grammar::Cmd;
  my $actions = Pakku::Grammar::Cmd::Actions;
  my $cmd     = $parser.parse( $string, :$actions ).ast<cmd>;
  ok $cmd ~~ $method, $msg;
}

done-testing;
