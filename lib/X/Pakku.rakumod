use X::Pakku::Spec;
use X::Pakku::Meta;
use X::Pakku::Test;
use X::Pakku::Build;

subset X::Pakku where 
  | X::Pakku::Spec
  | X::Pakku::Meta
  | X::Pakku::Test
  | X::Pakku::Build;
