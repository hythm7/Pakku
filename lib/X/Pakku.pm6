use Pakku::Log;

class X::Pakku {
  also is Exception;
}

class X::Pakku::NoCandy {
  also is X::Pakku;

  has $.spec;

  method message ( ) {

    "No candies for spec [$!spec]";
  }

}
