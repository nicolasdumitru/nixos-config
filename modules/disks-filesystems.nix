{
  pkgs,
  ...
}:

{
  # Enable udisks2, GNOME Disks and GVfs
  services.udisks2.enable = true;
  programs.gnome-disks.enable = true;
  services.gvfs = {
    enable = true;
    package = pkgs.gnome.gvfs;
  };
  # Udev rules for mounting Android phones
  services.udev.packages = [ pkgs.libmtp ];

  environment.systemPackages = with pkgs; [
    exfat
    exfatprogs
    libmtp
  ];

}
