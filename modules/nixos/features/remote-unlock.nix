{ config, lib, ... }:

let
  cfg = config.modules.remote-unlock;
in
{
  options.modules.remote-unlock = {
    enable = lib.mkEnableOption "unlocking the encrypted disk over SSH during boot";

    port = lib.mkOption {
      type = lib.types.port;
      default = 2222;
      description = ''
        Port of the boot-time SSH server. It differs from the normal SSH port
        because the boot-time server presents its own host key.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Wired networking only; the driver of the network card must be available
    # in the initrd (see the host's hardware module).
    boot.initrd.systemd.network = {
      enable = true;
      networks."10-wired" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };

    boot.initrd.network.ssh = {
      enable = true;
      inherit (cfg) port;
      authorizedKeys = config.modules.ssh-server.authorizedKeys;
      # A dedicated key, generated once on the machine: the initrd lives on the
      # unencrypted boot partition, so the regular host key must not be reused.
      #   ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };

    # `ssh -p 2222 root@host` lands directly in the passphrase prompt; boot
    # continues once the disk is unlocked. The local console prompt still works.
    boot.initrd.systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
  };
}
