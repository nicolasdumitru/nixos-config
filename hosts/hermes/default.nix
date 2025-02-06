{
  self,
  config,
  pkgs,
  ...
}:
let
  userName = "nick";
in
{
  imports = [
    # Hardware-specific configuration (auto-generated)
    # Generated by `nixos-generate-config --no-filesystems`
    ./hardware-configuration.nix

    # Disk partitioning and filesystem configuration
    # Managed by the `disko` utility for declarative disk management
    ./disko-config.nix

    # Shared Nix settings
    self.nixosModules.nix-config

    # Core system configuration and essential utilities
    self.nixosModules.core

    # Shells and prompts
    self.nixosModules.shell

    # General CLI utilities/tools
    self.nixosModules.utils

    # File management utilities
    self.nixosModules.file-utils

    # Desktop environment and GUI programs
    self.nixosModules.desktop

    # Development tools and programming languages
    self.nixosModules.development.default

    # Document viewers and editing tools
    self.nixosModules.documents

    # Disk management, mounting and filesystem tools
    self.nixosModules.disks-filesystems
  ];

  # Boot manager
  boot.loader.systemd-boot.enable = true;

  # System Hostname
  networking.hostName = "hermes";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Bucharest";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.mutableUsers = true;
  users.enforceIdUniqueness = true; # Require unique UIDs/GIDs
  users.users."${userName}" = {
    name = userName;
    isNormalUser = true;

    home = "/home/${userName}";
    createHome = true;

    useDefaultShell = false;
    shell = pkgs.bashInteractive;

    group = userName; # UPG
    extraGroups = [
      "wheel" # Grants sudo privileges
      "networkmanager"
      "scanner" # for SANE
      "lp" # for SANE
    ];

    # The initial password is meant to be changed right away. It's purpose is to
    # enable installing without a root password.
    initialPassword = userName;
  };
  # UPG
  users.groups."${userName}" = {
    name = userName;
    members = [ userName ];
  };

  # Automatic Nix garbage collection config
  nix.gc.automatic = false;

  # Enable hardware acceleration
  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the Nvidia open source kernel module.
    open = true;

    # Enable the Nvidia settings menu.
    nvidiaSettings = true;

    # Driver version.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    # These have to match the Bus ID values of the system!
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # TODO: Move this to a separate module
  # Enable support for SANE scanners
  hardware.sane.enable = true;
  # TODO: Set up network scanning (see
  # https://nixos.wiki/wiki/Scanners#Network_scanning). If pkgs.hplip doesn't
  # work, try pkgs.hplipWithPlugin.
  hardware.sane.extraBackends = [ pkgs.hplip ];

  # Define system packages
  environment.systemPackages = with pkgs; [
    simple-scan
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
