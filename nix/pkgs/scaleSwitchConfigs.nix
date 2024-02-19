{ stdenvNoCC
, perl
, gcc
}:

stdenvNoCC.mkDerivation {

  name = "scaleSwitchConfigs";

  buildInputs = [ perl gcc ];
  src = ../../.;
  buildCommand = ''
    cd switch-configuration
    make switch-maps-bundle
  '';
}
