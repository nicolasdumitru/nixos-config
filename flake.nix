{
  description = "Nick's NixOS, Home Manager, and dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bip39gen.url = "github:nicolasdumitru/bip39gen";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      flake-parts,
      ...
    }:
    let
      disko = import ./disko;
      dotfilesPath = ./dotfiles;
      hardware = import ./hardware;
      hosts = import ./hosts;
      modules = import ./modules { inherit inputs; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          inputs',
          lib,
          pkgs,
          system,
          ...
        }:
        let
          portablePkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          portableHome = home-manager.lib.homeManagerConfiguration {
            pkgs = portablePkgs;
            modules = [
              modules.homeManager.dotfiles.common
              modules.homeManager.neovim
              modules.homeManager.cliTools
              modules.homeManager.development
              {
                home.username = "portable-check";
                home.homeDirectory =
                  if lib.hasSuffix "-darwin" system then "/Users/portable-check" else "/home/portable-check";
              }
            ]
            ++ lib.optional (lib.hasSuffix "-linux" system) modules.homeManager.dotfiles.linux;
            extraSpecialArgs = {
              inherit dotfilesPath modules;
            };
          };
        in
        {
          devShells.default =
            let
              developmentPkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
            in
            developmentPkgs.mkShell {
              packages = with developmentPkgs; [
                nil
                nixd
                nixfmt
                nixfmt-tree
                lua-language-server
                stylua

                just
              ];
            };

          formatter = pkgs.nixfmt-tree;

          checks.portable-home = portableHome.activationPackage;

        }
        // lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          packages.disko-install = inputs'.disko.packages.disko-install;
          apps.disko-install = {
            type = "app";
            program = "${inputs'.disko.packages.disko-install}/bin/disko-install";
            meta.description = "Install a NixOS flake configuration using Disko";
          };
        };

      flake = {
        nixosConfigurations = {
          orpheus = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit dotfilesPath inputs modules;
            };
            modules = [
              hosts.orpheus.default
              inputs.nixos-wsl.nixosModules.default
              home-manager.nixosModules.home-manager
            ];
          };

          turing = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit
                disko
                dotfilesPath
                hardware
                hosts
                inputs
                modules
                self
                ;
              outputs = self.outputs;
            };
            modules = [
              hosts.turing.default
              inputs.disko.nixosModules.disko
              home-manager.nixosModules.home-manager
            ];
          };

          turing-bootstrap = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit
                disko
                dotfilesPath
                hardware
                hosts
                inputs
                modules
                self
                ;
              outputs = self.outputs;
            };
            modules = [
              hosts.turing.bootstrap
              inputs.disko.nixosModules.disko
            ];
          };
        };
      };
    };
}
