{ pkgs, ... }:

{
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
}
