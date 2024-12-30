{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nci.url = "github:yusdacra/nix-cargo-integration";
    devshell.url = "github:numtide/devshell";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
        inputs.nci.flakeModule
      ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        config,
        system,
        pkgs,
        ...
      }: let
        rust-toolchain = inputs.fenix.packages.${system}.stable.toolchain;

        buildStepDeps = with pkgs; [
          wayland
          gtk4
          pkg-config
          gobject-introspection
          glib
        ];
      in {
        packages.default =
          (pkgs.makeRustPlatform {
            cargo = rust-toolchain;
            rustc = rust-toolchain;
          })
          .buildRustPackage {
            pname = "app";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = buildStepDeps;
            nativeBuildInputs = with pkgs; [
              pkg-config
              openssl
            ];
          };
        devshells.default = {
          env = [
          ];
          commands = [
            {
              help = "alias of `cargo build`";
              name = "build";
              command = "cargo run";
            }
          ];
          packages = [
            rust-toolchain
          ];
        };
      };
    };
}
