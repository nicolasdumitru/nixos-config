{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.virtualization;
in
{
  options.modules.virtualization.enable = lib.mkEnableOption "libvirt/QEMU virtual machines";

  config = lib.mkIf cfg.enable {
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
  };
}
