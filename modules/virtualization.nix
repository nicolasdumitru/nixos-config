{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.virtualization;
in
{
  options.modules.virtualization = {
    vboxUsers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Users to add to vboxusers group";
    };
  };

  config = {
    boot.kernelParams = mkBefore [
      "kvm.enable_virt_at_load=0"
    ];

    # Docker
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
    };

    # VirtualBox
    virtualisation.virtualbox.host.enable = true;
    # virtualisation.virtualbox.host.enableExtensionPack = true;
    users.groups.vboxusers.members = cfg.vboxUsers;
  };
}
