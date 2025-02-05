{
  self,
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  userName = "nick";
in
{
  # You can import other NixOS modules here
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix
    ./disko-config.nix

    self.nixosModules.core
    self.nixosModules.shell
    self.nixosModules.utils
    self.nixosModules.file-utils

    self.nixosModules.desktop
    self.nixosModules.development.default
    self.nixosModules.documents

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
  users.users."${userName}" = {
    name = userName;
    uid = 1000;
    home = "/home/${userName}";
    isNormalUser = true;
    shell = pkgs.bashInteractive;
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This will add each flake input as a registry
  # to make nix3 commands consistent with the flake
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
    (lib.filterAttrs (_: lib.isType "flake")) inputs
  );

  # Add inputs to the system's legacy channels,
  # making legacy nix commands consistent as well
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  nix.settings = {
    # Enable flakes and new `nix` command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Enable automatic Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 30d";
  };

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
  system.stateVersion = "24.05";
}
