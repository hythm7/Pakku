
class X::Pakku::Repo::Add {
  also is Exception;

  has $.dist;

  method message ( ) {

    "ADD: ｢$!dist｣";

  }

}
