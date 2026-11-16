{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.wake-on-lan;
in
{
  options.modules.wake-on-lan.enable = lib.mkEnableOption "powering on through a magic packet on any wired network card";

  config = lib.mkIf cfg.enable {
    # Also requires Wake-on-LAN to be enabled in the firmware setup.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*|eth*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
    '';

    environment.systemPackages = [ pkgs.ethtool ];
  };
}
