{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.network-tools;
in
{
  options.modules.network-tools.enable = lib.mkEnableOption "network analysis tools";

  config = lib.mkIf cfg.enable {
    programs.mininet.enable = true;
    programs.wireshark = {
      enable = true;
      usbmon.enable = true;
      dumpcap.enable = true;
    };
    users.users.nick.extraGroups = [ "wireshark" ];

    environment.systemPackages = with pkgs; [
      wireshark
      netcat-gnu
      cachix
    ];
  };
}
