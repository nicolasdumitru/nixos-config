{ config, lib, ... }:

let
  cfg = config.modules.desktop.gnome;
in
{
  options.modules.desktop.gnome.enable = lib.mkEnableOption "the GNOME desktop";

  config = lib.mkIf cfg.enable {
    services.desktopManager.gnome.enable = true;
  };
}
