{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.applications;
in
{
  options.modules.desktop.applications.enable = lib.mkEnableOption "graphical applications";

  config = lib.mkIf cfg.enable {
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
      zed-editor
      kdePackages.okular
      onlyoffice-desktopeditors
      kdePackages.elisa
      spotify
      transmission_4-gtk
      wl-clipboard-rs
      kdePackages.qrca

      inputs.epicycle.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.bip39gen.packages.${stdenv.hostPlatform.system}.default
    ];
  };
}
