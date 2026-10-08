unit module Fixture::Bar;
use Fixture::Foo;
sub bar is export { 'bar with ' ~ foo }
