# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ inputs, lib, config, pkgs, ... }: {
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
  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; }))
    ((lib.filterAttrs (_: lib.isType "flake")) inputs);

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

  # User
  users.users.nick = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
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
      defaultSession = "none+awesome";

    };

    # Enable AwesomeWM
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        luarocks # is the package manager for Lua modules
        luadbi-mysql # Database abstraction layer
      ];
    };

    # Enable touchpad support
    libinput.enable = true;

  };

  # Enable slock
  programs.slock.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    zsh

    picom
    dmenu

    alacritty
    librewolf
    neovim

    ripgrep
    fd
    git
    curl
    wget

    xorg.xmodmap
    lightdm

    gcc
    clang
    rustup
    go

    glibc

    bear

    clang-tools
    lua-language-server
    nil
    nixfmt

    networkmanagerapplet
    feh
    fzf
    emacs
    newsboat

    dunst
    libnotify

    pass
    keepassxc
    btop
    pinentry-curses
    gnupg
    lshw
    xdotool
    xclip
    xsel
    pulseaudio
    pulsemixer
    sqlite
    bat
  ];

  fonts.packages = with pkgs; [
    #nerdfonts
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
  system.stateVersion = "23.05";
}
