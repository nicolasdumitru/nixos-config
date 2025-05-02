{
  nix-config = import ./nix-config.nix;
  core = import ./core.nix;
  shell = import ./shell.nix;
  utils = import ./utils.nix;
  file-utils = import ./file-utils.nix;

  desktop = import ./desktop.nix;

  development = {
    default = import ./development;
    c-cpp = import ./development/c-cpp.nix;
    dotnet = import ./development/dotnet.nix;
    rust = import ./development/rust.nix;
    python = import ./development/python.nix;
  };

  documents = import ./documents.nix;

  virtualization = import ./virtualization.nix;

  disks-filesystems = import ./disks-filesystems.nix;
}
