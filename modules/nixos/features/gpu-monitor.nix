{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.gpu-monitor;

  # Lint the script at build time with flake8, set up the way black documents
  # for code it formats: 88 columns, and without the two checks that
  # contradict its style.
  lint = pkgs.writeShellScript "gpu-monitor-lint" ''
    exec ${pkgs.python3Packages.flake8}/bin/flake8 --show-source \
      --max-line-length=88 --extend-ignore=E203,E701 "$1"
  '';

  monitor = pkgs.writers.makeScriptWriter {
    interpreter = lib.getExe pkgs.python3;
    check = lint;
  } "/bin/gpu-monitor" (builtins.readFile ./gpu-monitor.py);
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
