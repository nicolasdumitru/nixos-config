{
  self,
  config,
  lib,
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

    # Virtualization
    # (self.nixosModules.virtualization { vboxUsers = [ userName ]; })

    # Printing
    # (self.nixosModules.printing { driverPackages = [ pkgs.hplipWithPlugin ]; })

    # Scanning
    # (self.nixosModules.scanning {
    #   scanUsers = [ userName ];
    #   driverPackages = [ pkgs.hplipWithPlugin ];
    # })
  ];

  # Boot
  boot = {
    # Bootloader
    loader.systemd-boot.enable = true;
    loader.timeout = 0;

    # Graphical boot
    initrd.systemd.enable = true;
    initrd.verbose = false;

    plymouth = {
      enable = true;
      theme = "breeze";
    };

    consoleLogLevel = 4;
    kernelParams = lib.mkBefore [
      "quiet"
      "splash"
    ];
  };

  # Kernel configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # System Hostname
  networking.hostName = "turing";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

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

  # TODO: Setup hardware acceleration
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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    # WARNING: These have to match the Bus ID values of the system!
    amdgpuBusId = "PCI:101:0:0";
    nvidiaBusId = "PCI:100:0:0";
    # amdgpuBusId = "PCI:101@0:0:0";
    # nvidiaBusId = "PCI:100@0:0:0";
  };

  # Asus
  # Enable asusd
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # Enable supergfxd
  services.supergfxd.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
