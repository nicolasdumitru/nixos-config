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
              ./modules/home-manager/dotfiles/common.nix
              ./modules/home-manager/neovim-config.nix
              ./modules/home-manager/neovim-packages.nix
              ./modules/home-manager/cli-tools.nix
              (import ./modules/home-manager/development.nix { inherit inputs; })
              {
                home.username = "portable-check";
                home.homeDirectory =
                  if lib.hasSuffix "-darwin" system then "/Users/portable-check" else "/home/portable-check";
              }
            ]
            ++ lib.optional (lib.hasSuffix "-linux" system) ./modules/home-manager/dotfiles/linux.nix;
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

      flake =
        let
          withInputs = module: {
            imports = [ module ];
            _module.args.inputs = inputs;
          };
        in
        {
          homeModules = {
            dotfiles-common = import ./modules/home-manager/dotfiles/common.nix;
            dotfiles-linux = import ./modules/home-manager/dotfiles/linux.nix;
            neovim-config = import ./modules/home-manager/neovim-config.nix;
            neovim-packages = import ./modules/home-manager/neovim-packages.nix;
            cli-tools = import ./modules/home-manager/cli-tools.nix;
            development = import ./modules/home-manager/development.nix { inherit inputs; };
          };

          # Compatibility exports remain available, while internal host/profile
          # composition deliberately uses explicit file imports.
          nixosModules = {
            nix-config = withInputs ./modules/nixos/features/nix-config.nix;
            core = withInputs ./modules/nixos/profiles/base.nix;
            neovim = import ./modules/nixos/features/neovim.nix;
            shell = import ./modules/nixos/features/shell.nix;
            utils = import ./modules/nixos/features/cli-tools.nix;
            file-utils = import ./modules/nixos/features/cli-tools.nix;
            desktop = withInputs ./modules/nixos/features/desktop;
            desktop-cosmic = import ./modules/nixos/features/desktop/cosmic.nix;
            desktop-audio = import ./modules/nixos/features/desktop/audio.nix;
            desktop-applications = withInputs ./modules/nixos/features/desktop/applications.nix;
            desktop-fonts = import ./modules/nixos/features/desktop/fonts.nix;
            development = withInputs ./modules/nixos/features/development.nix;
            disks-filesystems = import ./modules/nixos/features/disks-filesystems.nix;
            ti-nspire = import ./modules/nixos/features/peripherals/ti-nspire.nix;
            virtualization = import ./modules/nixos/features/virtualization.nix;
            printing = import ./modules/nixos/features/peripherals/printing.nix;
            scanning = import ./modules/nixos/features/peripherals/scanning.nix;
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
