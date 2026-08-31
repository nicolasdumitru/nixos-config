{
  description = "Nick's NixOS, Home Manager, and dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      disko,
      home-manager,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        {
          inputs',
          pkgs,
          system,
          ...
        }:
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
              ];
            };

          formatter = pkgs.nixfmt-tree;

          packages.disko-install = inputs'.disko.packages.disko-install;
          apps.disko-install = {
            type = "app";
            program = "${inputs'.disko.packages.disko-install}/bin/disko-install";
            meta.description = "Install a NixOS flake configuration using Disko";
          };
        };

      flake = {
        # Compatibility exports for modules that were public before the move.
        # Host/profile composition below deliberately uses explicit file imports.
        nixosModules = {
          nix-config = import ./nixos/features/nix-config.nix;
          core = import ./nixos/profiles/base.nix;
          neovim = import ./nixos/features/neovim.nix;
          shell = import ./nixos/features/shell.nix;
          utils = import ./nixos/features/cli-tools.nix;
          file-utils = import ./nixos/features/cli-tools.nix;
          desktop = import ./nixos/features/desktop.nix;
          development = import ./nixos/features/development;
          rust = import ./nixos/features/development/rust.nix;
          disks-filesystems = import ./nixos/features/disks-filesystems.nix;
          ti-nspire = import ./nixos/features/peripherals/ti-nspire.nix;
          virtualization = import ./nixos/features/virtualization.nix;
          printing = import ./nixos/features/peripherals/printing.nix;
          scanning = import ./nixos/features/peripherals/scanning.nix;
        };

        nixosConfigurations = {
          turing = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs self;
              outputs = self.outputs;
            };
            modules = [
              ./hosts/turing
              disko.nixosModules.disko
              home-manager.nixosModules.home-manager
            ];
          };

          turing-bootstrap = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs self;
              outputs = self.outputs;
            };
            modules = [
              ./hosts/turing/bootstrap.nix
              disko.nixosModules.disko
            ];
          };
        };
      };
    };
}
