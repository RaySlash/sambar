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

  outputs = inputs @ {flake-parts, ...}: let
    gtk-overlay = final: prev: {
      gtk4 = prev.gtk4.overrideAttrs (oldAttrs: {
        src = oldAttrs.fetchurl {
          url = "https://download.gnome.org/sources/gtk/4.17/gtk-4.17.2.tar.xz";
          hash = "sha256-LsU+B9GMnwA7OeSmqDgFTZJZ4Ei2xMBdgMDQWqch2UQ=";
        };
      });
    };
  in
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
          libGL
          (lib.getLib gcc-unwrapped)
          xorg.libX11
          xorg.libXrandr
          xorg.libXinerama
          xorg.libXcursor
          xorg.libXi
          stdenv.cc.libc_bin
          pkg-config
          libxkbcommon
          clang
          cmake
          coreutils
          gtk4
          bashInteractive
          clang
          wayland
          glfw
        ];
      in {
        formatter = pkgs.alejandra;
        packages.default =
          (pkgs.makeRustPlatform {
            cargo = rust-toolchain;
            rustc = rust-toolchain;
          })
          .buildRustPackage {
            pname = "sambar";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = buildStepDeps;
            nativeBuildInputs = with pkgs; [
              wayland
              pkg-config
              openssl
            ];
          };
        devshells.default = {
          env = [
            {
              name = "LIBCLANG_PATH";
              value = "${pkgs.llvmPackages_12.libclang.lib}/lib";
            }
            {
              name = "LD_LIBRARY_PATH";
              value = "${
                pkgs.lib.makeLibraryPath buildStepDeps
              }:${pkgs.wayland}/lib:$LD_LIBRARY_PATH";
            }
          ];
          commands = [
            {
              help = "alias of `cargo build`";
              name = "build";
              command = "cargo run";
            }
          ];
          packages =
            [
              rust-toolchain
            ]
            ++ buildStepDeps;
        };
      };

      flake = {
        overlays.default = final: prev: {
          gtk4 = prev.gtk4.overrideAttrs (oldAttrs: {
            src = oldAttrs.fetchurl {
              url = "https://download.gnome.org/sources/gtk/4.17/gtk-4.17.2.tar.xz";
              hash = "sha256-LsU+B9GMnwA7OeSmqDgFTZJZ4Ei2xMBdgMDQWqch2UQ=";
            };
          });
        };
      };
    };
}
