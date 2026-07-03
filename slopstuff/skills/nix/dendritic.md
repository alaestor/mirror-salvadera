---
name: dendritic
description: Understanding dendritic nix flakes
license: MIT
disable-model-invocation: false
---

# About Dendritic Flakes

A *dendritic* flake organizes configuration as a tree of small feature-specific files where each leaf file is a `flake-parts` module that contributes to the flake's outputs.

- **`flake-parts`** — the module system backbone; each file can be a `flake-parts` module.
- **`import-tree`** — recursively discovers and imports every `.nix` file under a directory, so adding/removing a module is just a file operation (no merge conflicts in import lists).
- **`flake-file`** — generates `flake.nix` from Nix module options, so inputs and outputs are declared *inside* modules using the real Nix language rather than hand-edited in `flake.nix`. 

Typically, import-tree is used to recursively import everything from `./modules/`, though some project structures differ.


### Defining inputs in any module

Flake inputs are declared with `flake-file.inputs.<name>` and follow a typed Input Schema. Because they're regular Nix module options, allowing you to use full nix language (such as `lib.mkDefault`, interpolation, and conditionals). `flake-file` aggregates them into the generated `flake.nix`.

e.g.
```nix
# nixpkg-inputs.nix
{ config, lib, ... } : {

  options.common = {
    nixpkgs-stable-version = lib.mkOption {
      type= lib.types.str;
      default = "26.05";
      description = "The version to which 'stable-nixpkgs' should be set.";
    };
  };

  config = {
    flake-file.inputs = {
      stable-nixpkgs.url   = "nixpkgs/nixos-${config.common.nixpkgs-stable-version}";
      unstable-nixpkgs.url = "nixpkgs/nixos-unstable";
    };
  };
  
}

```

Always use `nix run .#write-flake` to regenerate `flake.nix` after adding inputs.

### Defining packages

Packages are declared under `flake.packages.<system>.<name>` (or per-system via `perSystem`). Each leaf module can contribute its own package:

```nix
# folder/default.nix
{ pkgs, ... }:
{
  flake.packages.x86_64-linux.hello = pkgs.callPackage ./package.nix { };
}
```

```nix
# folder/package.nix
{ stdenv, hello }:
stdenv.mkDerivation {
  pname = "hello-custom";
  inherit hello;
  # ...
}
```

Though for small derivations, it's often better to define it inline rather than making a separate package.nix file. Follow the project's exisiting layout and preferences.

### Defining apps

Apps follow the same pattern under `flake.apps.<system>.<name>`, with `program` pointing at a derivation:

```nix
# modules/apps/greet/default.nix
{ pkgs, ... }:
{
  flake.apps.x86_64-linux.greet = {
    type = "app";
    program = pkgs.callPackage ./greet.nix { };
  };
}
```

then you can `nix run .#greet`
