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

Import-tree is used to recursively import every `*.nix` file from `modules/`.

You can run `nix flake show` during development to verify that your modules are correctly contributing to the flake's outputs and to catch evaluation errors early.

### Avoid legacy patterns

Non-dendritic patterns, such as a `default.nix` containing `callPackage ./package.nix`, should be avoided. `import-tree` expects all `*.nix` files in the module tree path to be `flake-parts` modules; in-tree references like this will cause errors. If you require such patterns, consult the user about creating an out-of-tree place for `.nix` files (referrable by `${inputs.self}/otherfolder/file.nix`)

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

#### ⚠️ Recovery Note

If the flake enters a bad state due to invalid inputs or corrupted configuration, `nix run write-flake` may become unavailable. In these cases, a minimal bootstrapping `flake.nix` must used. You can run `unfuck-flake.sh` if present, or write out a `flake.nix` manually:

```nix
# minimal bootstrap flake
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    import-tree.url = "github:denful/import-tree";
  };
}
```

### Defining packages

In a dendritic flake, every `.nix` file is a `flake-parts` module. Avoid the traditional pattern of having a `default.nix` module that `callPackage`s a separate `package.nix` derivation; since `import-tree` imports all `.nix` files, this leads to infinite recursion.

Instead, define your packages directly as modules.

#### Per-System (Recommended)
Use `perSystem` to ensure the package is available on all supported architectures.

```nix
{
  perSystem = { pkgs, ... }: {
    packages.hello = pkgs.stdenv.mkDerivation {/*...*/};
  };
}
```

#### Explicit System
You can also target a specific system directly under `flake.packages`.

```nix
{ pkgs, ... }:
{
  flake.packages.x86_64-linux.hello = pkgs.stdenv.mkDerivation {/*...*/};
}
```

By defining the package inline within the module, you leverage the full power of the module system for dependency injection and configuration while keeping the filesystem clean.

### Defining apps

Apps follow the same pattern under `flake.apps.<system>.<name>`, with `program` pointing at a derivation:

```nix
# modules/apps/greet/default.nix
{ pkgs, ... }:
{
  flake.apps.x86_64-linux.greet = {
    type = "app";
    program = ...
  };
}
```

then you can `nix run .#greet`
