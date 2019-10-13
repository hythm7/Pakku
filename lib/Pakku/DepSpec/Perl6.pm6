use Pakku::Dist;

unit class Pakku::DepSpec::Perl6;
  also is CompUnit::DependencySpecification;


  method new ( %spec ) {

    self.bless: |%spec;

  }

# no type checking to avoid circular dependency
multi method ACCEPTS ( Pakku::DepSpec::Perl6:D: Pakku::Dist $dist --> Bool:D ) {

  return False unless $.short-name ~~ any( $dist.name, $dist.provides );
  return False unless $dist.ver    ~~ $.version-matcher;
  return False unless $dist.auth   ~~ $.auth-matcher;
  return False unless $dist.api    ~~ $.api-matcher;

  True;

}


