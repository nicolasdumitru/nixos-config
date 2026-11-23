{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.mail-fetch;
in
{
  options.modules.mail-fetch = {
    enable = lib.mkEnableOption "download-only mail fetching with isync";

    # Deliberately without a default, so that it is always set explicitly and
    # a change to the module can never stop or start fetching silently.
    automatic = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Whether to fetch at login and periodically. When off, mbsync and the
        mail-fetch service stay available for fetching by hand. Required when
        the module is enabled.
      '';
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "How often to fetch automatically, as a systemd calendar expression.";
    };
  };

  # TODO: Support macOS. Run mbsync from a launchd agent (`launchd.agents`) at
  # login and at the configured frequency, skipping it when there is no
  # isyncrc, and add a password lookup command that uses the Keychain (`security
  # find-generic-password -w`) on macOS and the keyring on Linux, so one
  # isyncrc works on both.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "modules.mail-fetch only supports Linux: it uses a systemd timer and the GNOME Keyring.";
      }
    ];

    home.packages = [
      pkgs.isync
      pkgs.libsecret
    ];

    # Accounts, passwords, and mail locations live in isync's own configuration
    # file, which is not part of this repository; see the README.
    systemd.user.services.mail-fetch = {
      Unit = {
        Description = "Download mail with mbsync";
        ConditionPathExists = "%E/isyncrc";
        # At login the network or the keyring may not be ready yet.
        StartLimitIntervalSec = 600;
        StartLimitBurst = 4;
      };
      Service = {
        Type = "oneshot";
        # These switches override the configuration file: only pull changes,
        # and only create, remove, or expunge on this machine. Whatever the
        # file says, nothing is changed on the servers.
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.isync}/bin/mbsync"
          "--all"
          "--pull"
          "--create-near"
          "--remove-near"
          "--expunge-near"
        ];
        Restart = "on-failure";
        RestartSec = 60;
      };
    };

    systemd.user.timers.mail-fetch = lib.mkIf cfg.automatic {
      Unit.Description = "Download mail at login and periodically";
      Timer = {
        OnStartupSec = "1min";
        OnCalendar = cfg.frequency;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
