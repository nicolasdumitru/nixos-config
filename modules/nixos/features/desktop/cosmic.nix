{ config, lib, ... }:

let
  cfg = config.modules.desktop.cosmic;
in
{
  options.modules.desktop.cosmic.enable = lib.mkEnableOption "the COSMIC desktop";

  config = lib.mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;
    services.system76-scheduler.enable = true;
    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
  };
}
