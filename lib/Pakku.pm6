use JSON::Fast;
use Hash::Merge::Augment;
use Pakku::Log;
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

has %!cnf;

has Pakku::Log           $!log;
has Pakku::Distribution  %!installed;
has Pakku::Distribution  @!installed;
has Pakku::Fetcher       $!fetcher;
has Pakku::Builder       $!builder;
has Pakku::Tester        $!tester;
has Pakku::Ecosystem     $!ecosystem;
has CompUnit::Repository $!repo;

submethod BUILD ( ) {

  self!init;
}

method add (

  :@spec!,
  :$into,
  Bool:D :$deps  = True,
  Bool:D :$build = True,
  Bool:D :$test  = True,
  Bool:D :$force = False,

) {

  my $repo = $into // $!repo;

  @spec .= grep( -> $spec { not self.installed: :$spec } );

  $!log.info: "Saul Goodman!" unless @spec;

  return unless @spec;

  my @cand = flat $!ecosystem.recommend: :@spec, :$deps;

  $!log.error: "No candies!" unless @cand;

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

submethod !init ( ) {

  my $cnf = Pakku::Grammar::Cnf.parsefile( 'cnf/cnf', actions => Pakku::Grammar::Cnf::Actions );
  my $cmd = Pakku::Grammar::Cmd.parse( @*ARGS, actions => Pakku::Grammar::Cmd::Actions );

  %!cnf = $cnf.ast.merge: $cmd.ast;

  my @source  = %!cnf<source>.flat;
  my $verbose = %!cnf<pakku><verbose> // 3;
  my $pretty  = %!cnf<pakku><pretty>  // True;
  my $repo    = %!cnf<pakku><repo>    // $*REPO;

  $!log     = Pakku::Log.new:     :$verbose, :$pretty;
  $!fetcher = Pakku::Fetcher.new: :$!log;
  $!builder = Pakku::Builder.new: :$!log;
  $!tester  = Pakku::Tester.new:  :$!log;


  $!repo = $repo;
  $!repo.repo-chain
     ==> grep( CompUnit::Repository::Installation )
     ==> map( *.installed )
     ==> flat()
     ==> map( -> $dist {
         Pakku::Distribution::Installed.new: meta => $dist.meta, prefix => $dist.prefix
       })
     ==> @!installed;

     %!installed = @!installed.map( -> $dist { $dist.name => $dist } );


  $!ecosystem = Pakku::Ecosystem.new: :$!log, :@source;

  given %!cnf<cmd> {

    self.add:    |%!cnf<add>    when 'add';
    self.remove: |%!cnf<remove> when 'remove';
    self.search: |%!cnf<search> when 'search';
  }

}
