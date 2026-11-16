{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.disks-filesystems;
in
{
  options.modules.disks-filesystems.enable = lib.mkEnableOption "removable disk, MTP, and extra filesystem support";

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
    programs.gnome-disks.enable = true;
    services.gvfs = {
      enable = true;
      package = pkgs.gnome.gvfs;
    };
    services.udev.packages = [ pkgs.libmtp ];

    environment.systemPackages = with pkgs; [
      exfat
      exfatprogs
      libmtp
    ];
  };
}
