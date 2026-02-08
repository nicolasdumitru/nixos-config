{
  description = "Nick's NixOS";

  inputs = {
    # Nixpkgs
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # disko
    disko-stable.url = "github:nix-community/disko";
    disko-stable.inputs.nixpkgs.follows = "nixpkgs-stable";
    disko-unstable.url = "github:nix-community/disko";
    disko-unstable.inputs.nixpkgs.follows = "nixpkgs";

    # flake-utils
    flake-parts.url = "github:hercules-ci/flake-parts";

    # rust-overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # bip39gen
    bip39gen.url = "github:nicolasdumitru/bip39gen";

    # home-manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      disko-stable,
      disko-unstable,
      rust-overlay,
      bip39gen,
      flake-parts,
      home-manager,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          devShells.default =
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
            in
            pkgs.mkShell {
              packages = with pkgs; [
                nil
                nixd
                nixfmt
                nixfmt-tree
              ];
            };

          formatter = pkgs.nixfmt-tree;
        };

      flake = {
        nixosModules = import ./modules;

        nixosConfigurations = {
          # Personal laptop
          turing = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            specialArgs = {
              inherit inputs self;
              outputs = self.outputs;
            };

            modules = [
              ./hosts/turing

              disko-unstable.nixosModules.disko
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.nick = import ./home;
                home-manager.extraSpecialArgs = { inherit inputs self; };
              }

              {
                nix.settings = {
                  # Settings can be checked after rebuilds using:
                  # `nix config show | rg <setting>`
                  # TODO: The default is preserved, but make appending/prepending
                  #       to the lists (substituters & trusted keys) explicit
                  substituters = [
                    "https://cache.nixos-cuda.org"
                    "https://nix-community.cachix.org"
                  ];
                  trusted-public-keys = [
                    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  ];
                };
              }
            ];
          };

          hermes = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            specialArgs = {
              inherit inputs self;
              outputs = self.outputs;
            };

            modules = [
              ./hosts/hermes

              disko-unstable.nixosModules.disko

              {
                nix.settings = {
                  # Settings can be checked after rebuilds using:
                  # `nix config show | rg <setting>`
                  # TODO: The default is preserved, but make appending/prepending
                  #       to the lists (substituters & trusted keys) explicit
                  substituters = [
                    "https://nix-community.cachix.org"
                    # "https://cuda-maintainers.cachix.org/"
                  ];
                  trusted-public-keys = [
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                    # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                  ];
                };
              }
            ];
          };

          atlas = nixpkgs-stable.lib.nixosSystem {
            system = "x86_64-linux";

            specialArgs = {
              inherit inputs self;
              outputs = self.outputs;
            };

            modules = [
              ./hosts/atlas

              disko-stable.nixosModules.disko

              # Fix the nixpkgs registry conflict
              {
                nix.registry.nixpkgs.flake = nixpkgs-stable;
                nix.registry.nixpkgs.to.path = nixpkgs-stable;
              }
            ];
          };
        };
      };
    };
}
