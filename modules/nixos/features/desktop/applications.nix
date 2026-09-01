{
  inputs,
  pkgs,
  ...
}:

{
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
    inputs.bip39gen.packages.${stdenv.hostPlatform.system}.default
  ];
}
