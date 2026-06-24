{
  description = "ROCm Pocket TTS ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      python = pkgs.python314;
      pythonPackages = python.pkgs;

      # Override pocket-tts to use torchWithRocm instead of the default torch
      pocket-tts-rocm = pythonPackages.pocket-tts.override {
        torch = pythonPackages.torchWithRocm;
      };

      lib-path = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc # libstdc++.so
        pkgs.libz # libz.so
        pkgs.alsa-lib # for sounddevice
        pkgs.portaudio # for sounddevice
        "/run/opengl-driver" # ROCm/AMDGPU driver
      ];

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs =
          with pkgs;
          [
            ffmpeg
            package-version-server
          ]
          ++ (with pythonPackages; [
            numpy
            requests
            sounddevice
            torchWithRocm
            pocket-tts-rocm
            mcp
            ruff
          ]);

        LD_LIBRARY_PATH = lib-path;

        shellHook = ''
          echo "✅ Nix dev shell activated"
        '';
      };

      packages.${system}.default = pkgs.writeShellApplication {
        name = "localvocal-server";
        runtimeInputs = [
          pkgs.ffmpeg
          (python.withPackages (ps: [
            ps.numpy
            ps.requests
            ps.sounddevice
            ps.torchWithRocm
            pocket-tts-rocm
            ps.mcp
          ]))
        ];
        text = ''
          export LD_LIBRARY_PATH="${lib-path}:''${LD_LIBRARY_PATH:-}"
          (cd ${./.} && exec python ./server.py)
        '';
      };
    };
}
