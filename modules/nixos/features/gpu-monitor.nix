{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.gpu-monitor;

  monitor = import ../../../scripts/python-script.nix { inherit lib pkgs; } {
    name = "gpu-monitor";
    src = ./gpu-monitor.py;
  };
in
{
  options.modules.gpu-monitor.enable = lib.mkEnableOption "logging what wakes the NVIDIA GPU, with a notification on battery";

  # Read the log with `journalctl -u gpu-monitor`.
  config = lib.mkIf cfg.enable {
    systemd.services.gpu-monitor = {
      description = "Log what wakes the discrete GPU";
      wantedBy = [ "multi-user.target" ];
      # For `notify-send`.
      path = [ pkgs.libnotify ];
      serviceConfig = {
        ExecStart = "${monitor}/bin/gpu-monitor";
        # Remove the kernel tracing instance the monitor created.
        ExecStopPost = "-${pkgs.coreutils}/bin/rmdir /sys/kernel/tracing/instances/gpu-monitor";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
