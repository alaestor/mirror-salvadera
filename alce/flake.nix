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

                find ./tests/ -name '*.test.lua' ! -name 'bundle.test.lua' -exec sh -c 'lua "$1"' _ {} \;
              '';
            }
          );
        };

        apps.test_bundle = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "test_bundle";
              runtimeInputs = [
                pkgs.lua5_3
                self'.packages.alcelib
              ];

              text = ''
                set -euo pipefail

                export LUA_PATH="?.lua;tools/?.lua;${self'.packages.alcelib}/?.lua;;"

                # The test file is relative to the flake root, but we need it available
                # at runtime. We can use a small hack or just point to the source.
                # Since the app is usually run from the project root:
                lua ./tests/bundle.test.lua
              '';
            }
          );
        };

        packages.default = self'.packages.alcelib;

        packages.alcelib = pkgs.stdenv.mkDerivation {
          pname = "alcelib";
          version = "0.1.0";
          src = ./.;
          buildInputs = [
            self'.packages.luapack
            pkgs.perl
          ];
          buildPhase = ''
            ${pkgs.lib.getExe self'.packages.luapack} -B -f src/main.lua -o alce.lua
            cp alce.lua alce-full.lua
            # Strip documentation metadata for production release
            # Remove __doc and __doc_returns multiline blocks
            # Matches the key, the multiline string, and the trailing comma/semicolon/whitespace
            #perl -i -0777 -pe 's/\s*__doc(_returns)?\s*=\s*\[\[[\s\S]*?\]\]\s*[,;]?\s*//g' alce.lua
            # Remove __doc_verbatim assignments
            #perl -i -pe 's/\s*__doc_verbatim\s*=\s*[^,;\n}]*[,;]?\s*(--.*)?//g' alce.lua
          '';
          installPhase = ''
            mkdir -p $out
            cp alce.lua $out/
            #cp alce-full.lua $out/
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
