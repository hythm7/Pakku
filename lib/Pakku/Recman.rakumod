use Pakku::Log;
use Pakku::Spec;
use Pakku::Fetch;

use Pakku::Recman::Index;
use Pakku::Recman::Local;
use Pakku::Recman::Ecosystem;

# The configured recommendation managers, by priority: the first that can
# recommend a dist wins, so a fallback ecosystem is only consulted on a miss.
unit class Pakku::Recman;

has @!recman;

submethod BUILD ( Pakku::Fetch :$fetch, IO::Path :$store, :@recman!, :$refresh ) {

  @recman
    ==> grep( -> %r { %r<active> ~~ Bool:D ?? %r<active> !! so %r<active> ~~ 1 | 'true' | 'yes' } )
    ==> sort( -> %r { %r<priority> // Inf } )
    ==> map( -> %r {

      my $name = %r<name> // 'recman';

      my $type = %r<type>
        // ( %r<mirrors> ?? 'ecosystem' !! ( %r<location> // '' ).starts-with( 'http' ) ?? 'legacy' !! 'local' );

      given $type {

        when 'ecosystem' {

          unless %r<mirrors> and $fetch and $store {
            log '🐞', header => 'REC', msg => ~$name, comment => 'ecosystem recman needs mirrors!';
            succeed Empty;
          }

          Pakku::Recman::Ecosystem.new:
            :$name,
            mirrors => %r<mirrors>.List.map( *.Str ),
            |( index  => ~$_ with %r<index>  ),
            |( source => ~$_ with %r<source> ),
            refresh => ( $refresh // %r<refresh> // 1 ),
            store   => $store.add( $name ),
            :$fetch;
        }

        when 'local' {

          unless %r<location> and %r<location>.IO.d {
            log '🐞', header => 'REC', msg => ~$name, comment => "{ %r<location> // '' }: no such directory!";
            succeed Empty;
          }

          Pakku::Recman::Local.new: :$name, location => %r<location>;
        }

        default {
          # the old recman.pakku.org protocol is gone
          log '🐞', header => 'REC', msg => ~$name, comment => "{ %r<location> // $type }: recman protocol no longer supported, run: pakku config recman reset";
          Empty;
        }
      }

    } )
    ==> @!recman;

}

method names ( ) { @!recman.map( *.name ).List }

method recommend ( ::?CLASS:D: Pakku::Spec::Raku:D :$spec! ) {

  for @!recman -> $recman { .return with $recman.recommend: :$spec }

  Nil;

}

method search (
    ::?CLASS:D:
    Pakku::Spec::Raku:D :$spec!,
    Bool:D              :$relaxed = True,
    Bool:D              :$latest  = False,
    Int:D               :$count   = 666,
  ) {

  flat @!recman.map: *.search: :$spec :$relaxed :$latest :$count;

}

method refresh ( :@name ) {

  my @ecosystem = @!recman.grep( Pakku::Recman::Ecosystem ).grep( -> $r { !@name or $r.name eq any @name } );

  log '🐞', header => 'IDX', msg => ~@name, comment => 'no such ecosystem!' if @name and not @ecosystem;

  @ecosystem.map( *.refresh: :force ).eager;

}
