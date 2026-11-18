{
  config,
  lib,
  pkgs,
  ...
}:

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

    # Terminal descriptions of the terminals that connect, so programs here
    # can draw on them: Ghostty's xterm-ghostty is not part of ncurses.
    environment.systemPackages = [ pkgs.ghostty.terminfo ];
  };
}
