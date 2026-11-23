{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.mail-fetch;

  # Fetches with retries, and reports failed fetches; see the script.
  mailFetch = import ../../scripts/python-script.nix { inherit lib pkgs; } {
    name = "mail-fetch";
    src = ./mail-fetch.py;
    runtimeInputs = [
      pkgs.isync
      pkgs.libnotify
      pkgs.systemd
    ];
  };
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
        OnFailure = [ "mail-fetch-failed.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${mailFetch}/bin/mail-fetch fetch";
      };
    };

    # Notifies at most once per login: the marker lives in the runtime
    # directory, which is removed when the user's last session ends.
    systemd.user.services.mail-fetch-failed = {
      Unit.Description = "Notify that mail could not be fetched";
      Service = {
        Type = "oneshot";
        ExecStart = "${mailFetch}/bin/mail-fetch notify-failure";
      };
    };

    # Automatic fetching silently does nothing without a configuration file,
    # so say so once at the start of each desktop session. A link whose target
    # is gone counts as missing.
    systemd.user.services.mail-fetch-config-check = lib.mkIf cfg.automatic {
      Unit = {
        Description = "Warn when automatic mail fetching has no isync configuration";
        ConditionPathExists = "!%E/isyncrc";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.escapeShellArgs [
          "${pkgs.libnotify}/bin/notify-send"
          "--app-name=mail-fetch"
          # Stay until dismissed; COSMIC otherwise hides it after 3 seconds.
          "--expire-time=0"
          "Mail is not being fetched"
          "Automatic mail fetching is on, but %E/isyncrc does not exist."
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
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
