{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  python,
}:

buildPythonPackage {
  pname = "minilua";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "aradooo";
    repo = "MiniLua";
    rev = "v1.1.0";
    hash = "sha256-vfE2mCe4QTdwowIAoCV6e9u5Xzj1EJEfemllIq6D1Xs=";
  };

  pyproject = true;

  build-system = [
    setuptools
    wheel
  ];

  dependencies = with python.pkgs; [
    click
    colorama
  ];

  doInstallCheck = true;

  installCheckPhase = ''
    $out/bin/minilua --version
  '';

  meta = with lib; {
    description = "MiniLua";
    license = licenses.mit;
  };
}
