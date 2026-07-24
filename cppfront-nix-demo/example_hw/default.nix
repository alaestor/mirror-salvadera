{ stdenv, lib, cppfront }:
let

  pname   = "example_hw";
  version = "0.1.0";
  exename = lib.toLower pname;

in stdenv.mkDerivation
{
  inherit pname version;

  nativeBuildInputs = [
    cppfront
  ];

  src = ./.;

  buildPhase = ''
    cppfront hello.cpp2 -pure-cpp2 -fno-rtti
    g++ hello.cpp -std=c++23 -Wall -Wextra -Wpedantic -Os -fno-rtti -o ${exename}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${exename} $out/bin
  '';
}
