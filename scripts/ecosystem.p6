#!/usr/bin/env perl6
#
#
use Concurrent::File::Find;
use LibCurl::HTTP :subs;
use JSON::Fast;

my @meta;
my $p6c-projects = 'https://ecosystem-api.p6c.org/projects.json';


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


@meta.append: flat jget $p6c-projects;

for find 'cpan', :extension<meta> -> $meta {

  next if $meta ~~ / DOOM /;

  @meta.append: from-json slurp $meta;

}

my $ecosystem = 'ecosystem.json';

given open $ecosystem, :w {
  .say( to-json @meta );
  .close;
}

