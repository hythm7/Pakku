#!/usr/bin/env perl6
#
use Test;

use lib 'lib';
use Pakku::Spec;

my \tests = %(
  ok => (
    [ 'Spec',                                     'Spec'                                     ],
    [ 'Spec::Name',                               'Spec::Name'                               ],
    [ 'Spec:ver<>',                               'Spec:ver<>'                               ],
    [ 'Spec:ver<*>',                              'Spec:ver<*>'                              ],
    [ 'Spec:ver<0.0.1>',                          'Spec:ver<0.0.1>'                          ],
    [ 'Spec:ver<0.0.1>:auth<name>',               'Spec:ver<0.0.1>:auth<name>'               ],
    [ 'Spec:ver<0.0.1>:auth<name>:api<>',         'Spec:ver<0.0.1>:auth<name>:api<>'         ],
    [ 'Spec:ver<0.0.1>:auth<name>:api<*>',        'Spec:ver<0.0.1>:auth<email>:api<*>'      ],
    [ 'Spec:ver<0.0.1>:auth<name>:api<*>',        'Spec:ver<0.0.1>:auth<email>:api<*>'       ],
    #[ 'Spec:ver<0.0.1>:auth<name<email>>:api<*>', 'Spec:ver<0.0.1>:auth<name<email>>:api<*>' ],
  ),
  nok => (
    [ 'Spec:abc<def>', 'Spec:abc<def>' ],
  );
);

#plan 42;


for flat tests<ok> -> $spec, $msg {

  isa-ok Pakku::Spec.new( :$spec ), Pakku::Spec, $msg;

}

for flat tests<nok> -> $spec, $msg {

  dies-ok { Pakku::Spec.new( :$spec ) }, $msg;

}


done-testing;

