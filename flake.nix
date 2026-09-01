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
    let
      modules = import ./module-tree.nix { inherit inputs; };
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
              modules.homeManager.neovimConfig
              modules.homeManager.neovimPackages
              modules.homeManager.cliTools
              modules.homeManager.development
              {
                home.username = "portable-check";
                home.homeDirectory =
                  if lib.hasSuffix "-darwin" system then "/Users/portable-check" else "/home/portable-check";
              }
            ]
            ++ lib.optional (lib.hasSuffix "-linux" system) modules.homeManager.dotfiles.linux;
            extraSpecialArgs = { inherit modules; };
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
          withContext = module: {
            imports = [ module ];
            _module.args = { inherit inputs modules; };
          };
        in
        {
          homeModules = {
            dotfiles-common = withContext modules.homeManager.dotfiles.common;
            dotfiles-linux = withContext modules.homeManager.dotfiles.linux;
            neovim-config = withContext modules.homeManager.neovimConfig;
            neovim-packages = withContext modules.homeManager.neovimPackages;
            cli-tools = withContext modules.homeManager.cliTools;
            development = withContext modules.homeManager.development;
          };

          # Compatibility exports remain available, while internal host/profile
          # composition deliberately uses explicit file imports.
          nixosModules = {
            nix-config = withContext modules.nixos.features.nixConfig;
            core = withContext modules.nixos.profiles.base;
            neovim = withContext modules.nixos.features.neovim;
            shell = withContext modules.nixos.features.shell;
            utils = withContext modules.nixos.features.cliTools;
            file-utils = withContext modules.nixos.features.cliTools;
            desktop = withContext modules.nixos.features.desktop.default;
            desktop-cosmic = withContext modules.nixos.features.desktop.cosmic;
            desktop-audio = withContext modules.nixos.features.desktop.audio;
            desktop-applications = withContext modules.nixos.features.desktop.applications;
            desktop-fonts = withContext modules.nixos.features.desktop.fonts;
            development = withContext modules.nixos.features.development;
            disks-filesystems = withContext modules.nixos.features.disksFilesystems;
            ti-nspire = withContext modules.nixos.features.peripherals.tiNspire;
            virtualization = withContext modules.nixos.features.virtualization;
            printing = withContext modules.nixos.features.peripherals.printing;
            scanning = withContext modules.nixos.features.peripherals.scanning;
          };

          nixosConfigurations = {
            turing = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs modules self;
                outputs = self.outputs;
              };
              modules = [
                modules.hosts.turing.default
                disko.nixosModules.disko
                home-manager.nixosModules.home-manager
              ];
            };

            turing-bootstrap = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs modules self;
                outputs = self.outputs;
              };
              modules = [
                modules.hosts.turing.bootstrap
                disko.nixosModules.disko
              ];
            };
          };
        };
    };
}
