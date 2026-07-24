# Experimental demo of [CPP2](https://github.com/hsutter/cppfront) using Nix

## Nix Shells

`nix develop` for the stdenv tools with cppfront.

`nix develop '.#qt'` to also get CMake, Qt, and QtCreator.

## Building

### Build cppfront

`nix build`

### Build & Run Examples

Cpp2 Hello World
```sh
nix build '.#example'
./result/bin/example_hw
```

Cpp2 with CMake and Qt
```sh
nix build '.#exampleqt'
./result/bin/example_hw_qt
```

Or with a dev shell
```
nix develop '.#qt'
cd example_hw_qt
cmake -H"." -B"build"
cmake --build build
./build/bin/example_hw_qt
```
