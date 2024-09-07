# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
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
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
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

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Unfree packages
      allowUnfree = true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
    (lib.filterAttrs (_: lib.isType "flake")) inputs
  );

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Enable automatic Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 7d";
  };

  # User
  users.users.nick = {
    name = userName;
    uid = 1000;
    home = "/home/${userName}";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
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

  # Enable/set up programs:
  programs = {
    # ZSH
    zsh.enable = true;

    # GnuPG agent
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    # Enable slock
    slock.enable = true;
  };

  # X11, LightDM, AwesomeWM
  services.xserver = {
    # Enable X11
    enable = true;

    # Keymap
    xkb.layout = "us";
    xkb.variant = "";

    # Enable lightdm
    displayManager = {
      lightdm.enable = true;
    };

    # Enable AwesomeWM
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks # is the package manager for Lua modules
        luadbi-mysql # Database abstraction layer
      ];
    };
  };

  # Enable touchpad support
  services.libinput.enable = true;

  # Enable sound with PipeWire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # Enable PulseAudio server emulation
    pulse.enable = true;
  };
  # Disable PulseAudio
  hardware.pulseaudio.enable = false;

  # systemd-logind configuration
  services.logind = {
    # Laptop lid switch behavior
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";

    extraConfig = "IdleAction=ignore";
  };

  # Use systemd-coredump for core dumps
  systemd.coredump.enable = true;

  # Enable printing with CUPS
  services.printing.enable = true;

  # Add printer drivers
  services.printing.drivers = [ pkgs.hplip ];

  # Enable udisks2, GNOME Disks and GVfs
  services.udisks2.enable = true;
  programs.gnome-disks.enable = true;
  services.gvfs.enable = true;
  # Udev rules for mounting Android phones
  services.udev.packages = [ pkgs.libmtp ];

  # Configure MPD
  services.mpd = {
    enable = true;
    startWhenNeeded = true;
    user = userName; # MPD must run under the same user as PipeWire
    musicDirectory = "${config.users.users.nick.home}/store/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
      auto_update "yes"
      restore_paused "yes"
    '';
  };
  systemd.services.mpd.environment = {
    # User-id must match above user.
    # MPD will look inside this directory for the PipeWire socket.
    XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.nick.uid}";
  };

  # Define system packages
  environment.systemPackages = with pkgs; [
    bash
    zsh
    coreutils-full
    eza
    bat
    diffutils
    findutils
    fd
    gnugrep
    ripgrep
    ripgrep-all
    gawk
    gnused
    neovim
    emacs
    tree-sitter
    gcc
    glibc
    clang
    libcxx
    gnumake
    cmake
    just
    git
    gnutar
    gzip
    xz
    zip
    unzip
    p7zip
    curl
    wget
    rsync
    gnupg
    keepassxc
    pass
    lightdm
    picom
    alacritty
    chromium
    thunderbird
    newsboat
    lf
    rename
    dmenu
    fzf
    rustup
    gdb
    clang-tools
    bear
    lua-language-server
    nil
    nixfmt-rfc-style
    shellcheck
    nodePackages.bash-language-server
    mpv
    mpd
    mpc-cli
    ncmpcpp
    nsxiv
    kdePackages.spectacle
    zathura
    texliveFull
    texlab
    rubber
    xdotool
    xorg.xmodmap
    xorg.xrandr
    arandr
    autorandr
    pulsemixer
    networkmanagerapplet
    xclip
    xsel
    dunst
    libnotify
    btop
    lsof
    lshw
    usbutils
    exfat
    exfatprogs
    pandoc
    libreoffice
    nodejs
    cups
    system-config-printer
    transmission_4-gtk
    udisks
    gnome-disk-utility
    gnome.gvfs
    libmtp
    nautilus
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
