use X::Pakku;
use Pakku::Log;

unit role Pakku::Command::Refresh;

# refresh the ecosystem indexes now, instead of waiting for them to go stale
multi method fly ( 'refresh', :@recman ) {

  die X::Pakku::Index.new: msg => 'refresh', comment => 'no recman configured!' unless self!recman and self!recman.names;

  log '🧚', header => 'RFR', msg => ~( @recman || self!recman.names );

  return if self!dont;

  self!recman.refresh: name => @recman;

}
