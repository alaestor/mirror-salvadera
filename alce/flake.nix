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

      perSystem =
        { pkgs, ... }:
        let
          commonDeps = with pkgs; [
            lua5_3
          ];
        in
        {
          devShells.default = pkgs.mkShell {
            packages = commonDeps;

            shellHook = ''
              echo "Development environment activated"
              export LUA_PATH="../?.lua;;"
              python --version
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
        };
    };
}
