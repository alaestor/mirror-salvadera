{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages = {
      orchestrator = pkgs.python3Packages.buildPythonApplication {
        pname = "conscrybe-orchestrator";
        version = "0.1.0";
        pyproject = true;
        build-system = [ pkgs.python3Packages.setuptools ];

        src = ../src/orchestrator;

        propagatedBuildInputs = [ pkgs.python3Packages.pyside6 ];

        doCheck = false;

        installPhase = ''
          mkdir -p $out/bin
          cp src/gui.py $out/bin/conscrybe
          chmod +x $out/bin/conscrybe

          cp src/cli.py $out/bin/conscrybe-cli
          chmod +x $out/bin/conscrybe-cli

          # Use a more generic python version path if possible or just a bin dir
          mkdir -p $out/lib/python3.11/site-packages/conscrybe
          cp src/*.py $out/lib/python3.11/site-packages/conscrybe/
        '';
      };
    };
  };
}
