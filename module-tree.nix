{ inputs }:

{
  files.dotfiles = ./dotfiles;

  packageSets = {
    cliTools = import ./lib/package-sets/cli-tools.nix;
    development = import ./lib/package-sets/development.nix;
    neovim = import ./lib/package-sets/neovim.nix;
  };

  homeManager = {
    cliTools = ./modules/home-manager/cli-tools.nix;
    development = import ./modules/home-manager/development.nix { inherit inputs; };
    dotfiles = {
      common = ./modules/home-manager/dotfiles/common.nix;
      linux = ./modules/home-manager/dotfiles/linux.nix;
    };
    neovimConfig = ./modules/home-manager/neovim-config.nix;
    neovimPackages = ./modules/home-manager/neovim-packages.nix;
  };

  nixos = {
    profiles = {
      base = ./modules/nixos/profiles/base.nix;
      bootstrap = ./modules/nixos/profiles/bootstrap.nix;
      laptop = ./modules/nixos/profiles/laptop.nix;
    };

    features = {
      asusLaptop = ./modules/nixos/features/asus-laptop.nix;
      cliTools = ./modules/nixos/features/cli-tools.nix;
      desktop = {
        default = ./modules/nixos/features/desktop/default.nix;
        applications = ./modules/nixos/features/desktop/applications.nix;
        audio = ./modules/nixos/features/desktop/audio.nix;
        cosmic = ./modules/nixos/features/desktop/cosmic.nix;
        fonts = ./modules/nixos/features/desktop/fonts.nix;
      };
      development = ./modules/nixos/features/development.nix;
      disksFilesystems = ./modules/nixos/features/disks-filesystems.nix;
      gaming = ./modules/nixos/features/gaming.nix;
      neovim = ./modules/nixos/features/neovim.nix;
      networkTools = ./modules/nixos/features/network-tools.nix;
      nixConfig = ./modules/nixos/features/nix-config.nix;
      nvidia = ./modules/nixos/features/nvidia.nix;
      peripherals = {
        printing = ./modules/nixos/features/peripherals/printing.nix;
        scanning = ./modules/nixos/features/peripherals/scanning.nix;
        tiNspire = ./modules/nixos/features/peripherals/ti-nspire.nix;
      };
      shell = ./modules/nixos/features/shell.nix;
      virtualization = ./modules/nixos/features/virtualization.nix;
    };
  };

  hardware = {
    rog-zephyrus-g16 = ./hardware/rog-zephyrus-g16.nix;
    tuf-f15 = ./hardware/tuf-f15.nix;
  };

  disko = {
    layouts.luksBtrfs = import ./disko/luks-btrfs.nix;
    rog-zephyrus-g16 = ./disko/rog-zephyrus-g16.nix;
    tuf-f15 = ./disko/tuf-f15.nix;
  };

  hosts.turing = {
    common = ./hosts/turing/common.nix;
    default = ./hosts/turing/default.nix;
    bootstrap = ./hosts/turing/bootstrap.nix;
  };
}
