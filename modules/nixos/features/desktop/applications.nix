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
    # TODO: revert to normal when fixed
    # gtk2 is marked broken in nixpkgs and the binary only links gtk3.
    (onlyoffice-desktopeditors.override { gtk2 = gtk3; })
    kdePackages.elisa
    spotify
    transmission_4-gtk
    wl-clipboard-rs
    kdePackages.qrca
    inputs.bip39gen.packages.${stdenv.hostPlatform.system}.default
  ];
}
