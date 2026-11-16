{ config, lib, ... }:

let
  desktop = config.modules.desktop;
  cfg = desktop.greeter;
in
{
  # The login screen for every desktop session. Only one display manager can
  # run, and each one lists all installed sessions.
  options.modules.desktop.greeter = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "cosmic-greeter"
        "gdm"
      ]
    );
    default =
      if desktop.cosmic.enable then
        "cosmic-greeter"
      else if desktop.gnome.enable then
        "gdm"
      else
        null;
    defaultText = lib.literalMD "the greeter of the enabled desktop, preferring COSMIC's; `null` without a desktop";
    description = "Display manager that shows the login screen, or `null` for none.";
  };

  config = lib.mkIf (cfg != null) {
    services.displayManager.cosmic-greeter.enable = cfg == "cosmic-greeter";
    services.displayManager.gdm.enable = cfg == "gdm";
  };
}
