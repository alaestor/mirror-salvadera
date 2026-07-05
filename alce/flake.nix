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
            python3
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

          apps.default = {
            type = "app";
            program = pkgs.lib.getExe (
              pkgs.writeShellApplication {
                name = "mkreadme";
                runtimeInputs = commonDeps;

                text = ''
                  set -euo pipefail

                  luaFile="''${1:-./alcelib.lua}"
                  mdFile="''${2:-./README.md}"

                  [[ -f "$luaFile" ]] || {
                    echo "Lua file not found: $luaFile" >&2
                    exit 1
                  }

                  python ./lua2md.py "$luaFile" "$mdFile"
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
