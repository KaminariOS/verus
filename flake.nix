{
  description = "Verified Rust for low-level systems code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane, ... }: let
    # System types to support.
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        rust-overlay.overlays.default
      ];
    };

    inherit (pkgs) lib;

    pinnedRust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
    pinnedZ3 = pkgs.callPackage ./tools/z3.nix {};

    cranePkgs = pkgs.callPackage ./crane.nix {
      craneLib = (crane.mkLib pkgs).overrideToolchain pinnedRust;
      rust = pinnedRust;
      z3 = pinnedZ3;
    };
  in {
    packages = {
      inherit (cranePkgs) vargo verus verus-no-std verus-alloc line-count;
    };
    devShell = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        pinnedRust
        pinnedZ3
      ];

      buildInputs = with pkgs; [
        zlib
      ];

      VERUS_Z3_PATH = lib.getExe pinnedZ3;

      VARGO_TOOLCHAIN = "host";

      # For vstd_build
      #RUST_SYSROOT = pinnedRust;

      # For rust_verify
      shellHook = ''
        export LD_LIBRARY_PATH="${pinnedRust}/lib";
      '' + lib.optionalString pkgs.stdenv.isDarwin ''
        export DYLD_LIBRARY_PATH="${pinnedRust}/lib";
      '';
    };
  });
}
