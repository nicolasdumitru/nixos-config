{
  pkgs,
  inputs,
  ...
}:

{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.system76-scheduler.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-latest;
  };
  programs.kdeconnect.enable = false;

  environment.systemPackages = with pkgs; [
    ghostty
    brave
    loupe
    keepassxc
    veracrypt
    signal-desktop
    obsidian
    kdePackages.okular
    onlyoffice-desktopeditors
    kdePackages.elisa
    spotify
    transmission_4-gtk
    wl-clipboard-rs
    kdePackages.qrca
    inputs.bip39gen.packages.x86_64-linux.default
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
    corefonts
    vista-fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}
