{
  pkgs,
  ...
}:

{
  # KDE Plasma
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;
  #
  # environment.plasma6.excludePackages = with pkgs.kdePackages; [
  #   konsole
  #   kate
  # ];

  # COSMIC Desktop
  services.desktopManager.cosmic.enable = true;
  # services.displayManager.cosmic-greeter.enable = true; TODO: Enable when fixed

  # systemd-logind configuration
  services.logind = {
    # Laptop lid switch behavior
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";

    extraConfig = "IdleAction=ignore";
  };

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
  services.pulseaudio.enable = false;

  # Enable touchpad support
  services.libinput.enable = true;

  # Configure Bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  environment.systemPackages = with pkgs; [
    alacritty
    brave
    thunderbird
    keepassxc
    loupe
    kdePackages.elisa

    nautilus
    deja-dup

    signal-desktop
    element-desktop

    stockfish
    en-croissant

    gnome-system-monitor

    # wl-clipboard-rs # TODO: Enable later (currently not supported by COSMIC)
    xsel
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}
