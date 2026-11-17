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

    epicycle.url = "github:nicolasdumitru/epicycle";
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
          # One formatter for the whole tree: `nix fmt`, or `treefmt` in the
          # development shell, formats Nix, Lua, and Python files.
          treefmt = pkgs.nixfmt-tree.override {
            runtimeInputs = [
              pkgs.stylua
              pkgs.black
            ];
            settings.formatter = {
              stylua = {
                command = "stylua";
                options = [ "--verify" ];
                includes = [ "*.lua" ];
              };
              black = {
                command = "black";
                includes = [ "*.py" ];
              };
            };
          };

          portablePkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          portableHome = home-manager.lib.homeManagerConfiguration {
            pkgs = portablePkgs;
            modules = [
              modules.homeManager
              {
                modules = {
                  dotfiles.enable = true;
                  neovim.enable = true;
                  cli-tools.enable = true;
                  development.enable = true;
                  zsh.enable = true;
                };

                home.stateVersion = "26.05";
                home.username = "portable-check";
                home.homeDirectory =
                  if lib.hasSuffix "-darwin" system then "/Users/portable-check" else "/home/portable-check";
              }
            ];
            extraSpecialArgs = {
              inherit dotfilesPath;
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

                python3
                pyrefly
                black

                lua-language-server
                stylua

                just
                treefmt
              ];
            };

          formatter = treefmt;

          checks.formatting = pkgs.runCommand "formatting" { nativeBuildInputs = [ treefmt ]; } ''
            cp -r ${self} tree
            chmod -R u+w tree
            treefmt --ci --tree-root tree
            touch $out
          '';

          checks.portable-home = portableHome.activationPackage;

        }
        // lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          packages.disko-install = inputs'.disko.packages.disko-install;
          packages.installer-iso = self.nixosConfigurations.lovelace.config.system.build.isoImage;
          apps.disko-install = {
            type = "app";
            program = "${inputs'.disko.packages.disko-install}/bin/disko-install";
            meta.description = "Install a NixOS flake configuration using Disko";
          };
        };

      flake = {
        nixosConfigurations = {
          babbage = nixpkgs.lib.nixosSystem {
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
              hosts.babbage.default
              inputs.disko.nixosModules.disko
              home-manager.nixosModules.home-manager
            ];
          };

          babbage-bootstrap = nixpkgs.lib.nixosSystem {
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
              hosts.babbage.bootstrap
              inputs.disko.nixosModules.disko
            ];
          };

          lovelace = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit dotfilesPath inputs modules;
            };
            modules = [
              hosts.lovelace.default
              home-manager.nixosModules.home-manager
            ];
          };

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
