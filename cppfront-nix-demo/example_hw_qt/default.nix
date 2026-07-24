{ stdenv
, lib
, qt6
, cppfront
, cmake
, wrapQtAppsHook
}:
let

  pname   = "example_hw_qt6";
  version = "0.1.0";

in stdenv.mkDerivation
{
  inherit pname version;

  src = ./.;

  buildInputs = [
    qt6.qtbase
  ];

  nativeBuildInputs = [
    cmake
    cppfront
    wrapQtAppsHook
  ];

  installPhase = ''
    ls -lsa
    mkdir -p $out
    cp -r ./bin $out
  '';
}
