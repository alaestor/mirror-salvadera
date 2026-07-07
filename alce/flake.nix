{
  description = "Alaestor's Cheat Engine Library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, self', ... }: {

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.lua5_3
            self'.packages.minilua
            self'.packages.luapack
          ];

          shellHook = ''
            echo "Development environment activated"
            export LUA_PATH="../?.lua;;"
            lua -v
            luapack --version
            minilua --version
          '';
        };

        apps.mkdoc = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "mkdoc";
              runtimeInputs = [ pkgs.lua5_3 ];

              text = ''
                set -euo pipefail

                export LUA_PATH="../?.lua;;"

                export ALCE_DOC_OUTPUT="README.md"
                lua -e "package.path = package.path .. ';src?.lua;src/?.lua;tools?.lua;tools/?.lua'; require('alce.tools.docs_gen')"
              '';
            }
          );
        };

        apps.test = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "test";
              runtimeInputs = [ pkgs.lua5_3 ];

              text = ''
                set -euo pipefail

                export LUA_PATH="../?.lua;;"

                find ./tests/ -name '*.test.lua' -exec sh -c 'lua "$1"' _ {} \;
              '';
            }
          );
        };

        packages.default = self'.packages.alcelib;

        packages.alcelib = pkgs.stdenv.mkDerivation {
          pname = "alcelib";
          version = "0.1";
          src = ./.;
          buildInputs = [ self'.packages.luapack ];
          buildPhase = ''
            ${pkgs.lib.getExe self'.packages.luapack} -B -f src/main.lua -o alce.lua
          '';
          installPhase = ''
            mkdir -p $out
            cp alce.lua $out/
          '';
        };

        packages.luapack = pkgs.callPackage ./pkgs/luapack.nix { };

        packages.minilua =
          let
            python = pkgs.python312;
          in
          python.pkgs.callPackage ./pkgs/minilua.nix { };
      };
    };
}
