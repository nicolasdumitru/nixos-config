{ config, lib, ... }:

let
  cfg = config.modules.greeter;
in
{
  # The login screen for every desktop session. Only one display manager can
  # run, and each one lists all installed sessions.
  options.modules.greeter = lib.mkOption {
    type = lib.types.enum [
      "cosmic-greeter"
      "gdm"
    ];
    default = "cosmic-greeter";
    description = "Display manager that shows the login screen.";
  };

  config = {
    services.displayManager.cosmic-greeter.enable = cfg == "cosmic-greeter";
    services.displayManager.gdm.enable = cfg == "gdm";
  };
}
