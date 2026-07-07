{ pkgs, ... }:
let
  pname = "luapack";
  version = "0.1.1";
  src = pkgs.fetchFromGitHub {
    owner = "the-unnamed-goose";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-WDBIF7eiRUdmhWYZG4Gbi1p0p6d5CYHVbXTFRbofpWM=";
  };
in
pkgs.rustPlatform.buildRustPackage {
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
}
