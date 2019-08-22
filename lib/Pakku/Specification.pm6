use Pakku::Distribution;

unit class Pakku::Specification;
  also is CompUnit::DependencySpecification;

method name ( ) {

  $.short-name

}

method version ( ) {

  return Version.new  if $.version-matcher ~~ Bool;

  Version.new: $.version-matcher;
}

method auth ( ) {

  return Any if $.auth-matcher ~~ Bool;

  $.auth-matcher;

}

method api ( ) {

  return Any if $.api-matcher ~~ Bool;

  $.api-matcher;

}


multi method ACCEPTS ( Pakku::Specification:D: Pakku::Distribution:D $dist --> Bool:D ) {

  return False unless $.name ~~ any( $dist.name, $dist.provides );
  return False unless Version.new( $dist.version ) ~~ $.version;
  return False unless $dist.auth ~~ $.auth;
  return False unless $dist.api  ~~ $.api-matcher;

  True;

}
