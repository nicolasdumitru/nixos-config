{
  asusLaptop = ./asus-laptop.nix;
  cliTools = ./cli-tools.nix;
  desktop = import ./desktop;
  development = ./development.nix;
  disksFilesystems = ./disks-filesystems.nix;
  gaming = ./gaming.nix;
  neovim = ./neovim.nix;
  networkTools = ./network-tools.nix;
  nixConfig = ./nix-config.nix;
  nvidia = ./nvidia.nix;
  peripherals = import ./peripherals;
  shell = ./shell.nix;
  virtualization = ./virtualization.nix;
}
