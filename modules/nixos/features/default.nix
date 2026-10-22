{
  asusLaptop = ./asus-laptop.nix;
  desktop = import ./desktop;
  development = ./development.nix;
  disksFilesystems = ./disks-filesystems.nix;
  networkTools = ./network-tools.nix;
  nixConfig = ./nix-config.nix;
  nvidia = ./nvidia.nix;
  peripherals = import ./peripherals;
  shell = ./shell.nix;
  sqlServer = ./sql-server.nix;
  virtualization = ./virtualization.nix;
}
