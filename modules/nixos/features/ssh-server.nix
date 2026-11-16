{ config, lib, ... }:

let
  cfg = config.modules.ssh-server;
in
{
  options.modules.ssh-server = {
    enable = lib.mkEnableOption "the OpenSSH server with key-only logins";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Public keys allowed to log in as nick, and to unlock the disk remotely.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    users.users.nick.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
