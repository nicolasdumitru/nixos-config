{
  core = import ./core.nix;
  shell = import ./shell.nix;
  utils = import ./utils.nix;
  file-utils = import ./file-utils.nix;

  desktop = import ./desktop.nix;
  development = {
    default = import ./development;
    c-cpp = import ./development/c-cpp.nix;
    python = import ./development/python.nix;
  };
  documents = import ./documents.nix;

  disks-filesystems = import ./disks-filesystems.nix;
}
