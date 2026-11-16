{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.profiles.server;
in
{
  options.modules.profiles.server.enable =
    lib.mkEnableOption "headless server policy (includes the base profile)";

  config = lib.mkIf cfg.enable {
    modules.profiles.base.enable = true;
    modules.ssh-server.enable = true;

    # A laptop used as a server keeps running with its lid closed.
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
      IdleAction = "ignore";
    };

    # Turn the built-in screen off when the console is idle.
    boot.kernelParams = [ "consoleblank=60" ];
  };
}
