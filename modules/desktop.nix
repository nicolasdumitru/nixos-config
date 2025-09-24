{
  pkgs,
  ...
}:

{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # COSMIC Desktop
  # services.desktopManager.cosmic.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;
  # environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1; # Wayland clipboard

  # systemd-logind configuration
  services.logind.settings.Login = {
    # Laptop lid switch behavior
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";

    IdleAction = "ignore";
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

  # Thunderbird
  programs.thunderbird.enable = true;
  programs.thunderbird.package = pkgs.thunderbird-latest;

  environment.systemPackages = with pkgs; [
    alacritty
    brave
    keepassxc
    loupe

    signal-desktop-bin

    obsidian

    kdePackages.elisa
    spotify

    wl-clipboard-rs
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    corefonts
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
