use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Grammar::Cnf;
use Pakku::Grammar::Cmd;
use Pakku::Ecosystem;
use Pakku::Fetcher;
use Pakku::Builder;
use Pakku::Tester;
use Pakku::Specification;
use Pakku::Distribution::Path;
use Pakku::Distribution::Installed;

unit class Pakku:ver<0.0.1>:auth<cpan:hythm>;

has %!config;

has Pakku::Distribution  %!installed;
has Pakku::Distribution  @!installed;
has Pakku::Fetcher       $!fetcher;
has Pakku::Builder       $!builder;
has Pakku::Tester        $!tester;
has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;

submethod BUILD ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!config = $cnf.ast.merge: $cmd.ast;

  $!fetcher = Pakku::Fetcher;
  $!builder = Pakku::Builder;
  $!tester  = Pakku::Tester;

  $!repo   = %!config<pakku><repo> // $*REPO;

  my @source = flat %!config<source>;

  $!repo.repo-chain
     ==> grep( CompUnit::Repository::Installation )
     ==> map( *.installed )
     ==> flat()
     ==> map( -> $dist {
         Pakku::Distribution::Installed.new: meta => $dist.meta, prefix => $dist.prefix
       })
     ==> @!installed;

     %!installed = @!installed.map( -> $dist { $dist.name => $dist } );


  $!ecosystem = Pakku::Ecosystem.new: :@source;

  given %!config<cmd> {

    self.add:    |%!config<add>    when 'add';
    self.remove: |%!config<remove> when 'remove';
    self.search: |%!config<search> when 'search';
  }

}

method add ( :@spec!, :$into, :$deps, :$build = True, :$test = True, :$force = False ) {

  my $repo = $into // $!repo;

  @spec .= grep( -> $spec { not self.installed: :$spec } );

  say "It's all good man" unless @spec;
  return unless @spec;

  my @cand = flat $!ecosystem.recommend: :@spec;

  say "No candies!" unless @cand;
  return unless @cand;

  @cand .= grep( -> $dist { not self.installed: :$dist } );

  for @cand {

    my $prefix = $!fetcher.fetch: src => .source-url;

    my $dist = Pakku::Distribution::Path.new: $prefix;

    $!builder.build: :$dist if $build;
    $!tester.test:   :$dist if $test;

    say "installing {$dist.name}";
    $repo.install( $dist, :$force );

  }

}

method remove ( :@spec!, :$from, :$deps ) {

  # Bug: Only %meta<files> getting deleted

  my $repo = $from // $!repo;

  for @spec -> $spec {

    my $dist = $repo.candidates( $spec ).head;

    # Temp workaround for rakudo issue #3153
    $dist.meta<api> = '' if $dist.meta<api> ~~ Version.new: 0;

    $repo.uninstall: $dist if so $dist;

  }
}

method search ( :@spec! ) {

  $!ecosystem.recommend: :@spec;

}


multi submethod installed ( Pakku::Specification:D :$spec! ) {

  my @cand;

  my $name = $spec.short-name;

  return flat %!installed{$name} if so %!installed{$name};

  return @!installed.grep( *.provides: :$name).grep( * ~~ $spec).sort( *.version );

}

multi submethod installed ( Pakku::Distribution:D :$dist! --> Bool ) {

  return True if so %!installed{$dist.name};


  return True if @!installed.grep( -> $inst { $dist.name ~~ $inst.provides } );

  #return True if @!installed.grep: *.provides: name => $dist.name;

  return False;

}
