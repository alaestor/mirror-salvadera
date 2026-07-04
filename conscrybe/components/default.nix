{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages = {
      conscrybe-default = pkgs.symlinkJoin {
        name = "conscrybe-default";
        paths = [
          # We can reference the orchestrator package defined in orchestrator/default.nix
          # by looking it up in the current system's packages or using a shared reference.
          # Since we are in a module, we can't easily reference other modules' outputs
          # directly unless we use the module system.
          # The easiest way in a dendritic flake for a meta-package is to
          # just call the lib file.
          (pkgs.callPackage ./orchestrator/package.lib { })
          pkgs.sox
          pkgs.wl-clipboard
          pkgs.llm
          pkgs.whisper-cpp
        ];
        description = "ConScrybe default environment with all required CLI tools";
      };
    };
  };
}
