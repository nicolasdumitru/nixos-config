{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.virtualization.virt-manager;
in
{
  options.modules.virtualization.virt-manager = {
    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Users to add to the libvirtd group";
    };
  };

  config = {
    virtualisation.libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };
    programs.virt-manager.enable = true;

    users.extraGroups.libvirtd.members = cfg.users;
  };
}
