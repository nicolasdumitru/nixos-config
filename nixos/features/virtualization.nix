{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = [ pkgs.virtiofsd ];
  };
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;

  users.users.nick.extraGroups = [
    "libvirtd"
    "kvm"
  ];
}
