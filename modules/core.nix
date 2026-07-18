{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.neovim
  ];

  # Default shell
  users.defaultUserShell = pkgs.bashInteractive;

  # Primary text editor
  modules.neovim.enable = true;

  environment.systemPackages = with pkgs; [
    # Bash (many systems/programs depend on bash)
    bashInteractive

    # Core system utilities
    coreutils
    util-linux

    # Fundamental development and system tools
    gcc # GNU C compiler
    glibc # GNU C standard library
    binutils # GNU linker, assembler, etc.

    # Basic system information and management
    htop
    procps # ps, top, etc.

    # Basic network diagnostics
    inetutils # ping, traceroute, etc.

    # Network utilities
    wget
    curl
    openssh

    # NixOS-specific (for the configuration)
    git
    just
  ];
}
