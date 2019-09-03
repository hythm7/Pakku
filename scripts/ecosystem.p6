#!/usr/bin/env perl6
#
#
use Concurrent::File::Find;
use LibCurl::HTTP :subs;
use JSON::Fast;

my $ecosystem = 'ecosystem.json';

#my $p6c-meta = 'https://raw.githubusercontent.com/perl6/ecosystem/master/META.list';
#
#for LibCurl::Easy.new( URL => $p6c-meta ).perform.content.lines -> $URL {
#
#  my $meta = LibCurl::Easy.new( :$URL ).perform.content;
#  $ecosystem.IO.spurt: "$meta,\n", :append;
#
#}
#

my @cmd = <
    rsync
    -av
    -m
    --include=/id/*/*/*/Perl6/*.meta
    --include=*/
    --exclude=*
    cpan-rsync.perl.org::CPAN/authors/id
    cpan
  >;

  run @cmd, :!out, :!err;

for find 'cpan', :extension<meta> -> $meta {

  next if $meta ~~ / DOOM /; #JSON::Fast not able to parse

  $ecosystem.IO.spurt: "{$meta.IO.slurp},\n", :append;

}

#say @meta;
