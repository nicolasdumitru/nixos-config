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

    # libvirt keeps its rules in its own nftables table, so the system firewall
    # must separately let guests on the default NAT network reach the host's
    # DHCP and DNS.
    networking.firewall.interfaces.virbr0 = {
      allowedUDPPorts = [
        53
        67
      ];
      allowedTCPPorts = [ 53 ];
    };

    users.users.nick.extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };
}
