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
              self'.packages.luapack
            ];

            shellHook = ''
              echo "Development environment activated"
              export LUA_PATH="../?.lua;;"
              luapack --version
              lua -v
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

          #TODO packages.alcelib = ...

          packages.luapack = let
            pname = "luapack";
            version = "0.1.1";
            src = pkgs.fetchFromGitHub {
              owner = "the-unnamed-goose";
              repo = pname;
              rev = "v${version}";
              hash = "sha256-WDBIF7eiRUdmhWYZG4Gbi1p0p6d5CYHVbXTFRbofpWM=";
            };
          in pkgs.rustPlatform.buildRustPackage {
            inherit pname version src;

            cargoLock.lockFile = "${src}/Cargo.lock";

            doCheck = false;

            meta = with pkgs.lib; {
              description = "A basic rust application for efficiently bundling Lua scripts into monolithic releases.";
              homepage = "https://github.com/the-unnamed-goose/luapack";
              license = licenses.mpl20;
              mainProgram = "luapack";
              platforms = platforms.unix;
            };
          };
        };
    };
}
