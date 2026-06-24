{
  description = "lua2md environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems f;

    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          commonDeps = with pkgs; [ python3 ];
        in
        {
          default = pkgs.mkShell {
            buildInputs = commonDeps;

            shellHook = ''
              echo "Python development environment activated"
              echo "Python version: $(python --version)"
            '';
          };
        }
      );

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          commonDeps = with pkgs; [ python3 ];
        in
        rec {
          mkreadme = {
            type = "app";
            program = toString (pkgs.writeShellScript "mkreadme" ''
              set -euo pipefail
              export PATH="${pkgs.lib.makeBinPath commonDeps}:$PATH"
              LUA_FILE="''${1:-./alcelib.lua}"
              MD_FILE="''${2:-./README.md}"
              # Validate all required arguments
              for var_name in LUA_FILE MD_FILE; do
              if [[ -z "''${!var_name:-}" ]]; then
                  echo "Error: $var_name is required but empty" >&2
                  exit 1
                fi
              done
              if [[ ! -f "$LUA_FILE" ]]; then
                echo "Error: Lua file not found: $LUA_FILE" >&2
                exit 1
              fi
              echo "Running lua2md to create the README.md file..."
              echo "Python: $(python --version)"
              rm -rf "$MD_FILE"
              python ./lua2md.py "$LUA_FILE" "$MD_FILE"
            '');
          };
          default = mkreadme;
        }
      );
    };
}
