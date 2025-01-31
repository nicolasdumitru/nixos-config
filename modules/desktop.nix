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
  services.pulseaudio.enable = false;

  # systemd-logind configuration
  services.logind = {
    # Laptop lid switch behavior
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";

    extraConfig = "IdleAction=ignore";
  };

  # Configure Bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  environment.systemPackages = with pkgs; [
    alacritty
    chromium
    thunderbird
    loupe
    gnome-system-monitor
    # wl-clipboard-rs # TODO: Enable later (currently not supported by COSMIC)
    xsel
  ];
}
