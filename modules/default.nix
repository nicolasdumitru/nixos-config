{
  nix-config = import ./nix-config.nix;
  core = import ./core.nix;
  shell = import ./shell.nix;
  utils = import ./utils.nix;
  file-utils = import ./file-utils.nix;

  desktop = import ./desktop.nix;

  development = {
    default = import ./development;
    rust = import ./development/rust.nix;
  };

  disks-filesystems = import ./disks-filesystems.nix;
  virtualization = import ./virtualization.nix;

  printing = import ./printing.nix;
  scanning = import ./scanning.nix;
}
