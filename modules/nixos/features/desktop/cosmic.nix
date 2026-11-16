{ modules, ... }:

{
  imports = [
    modules.nixos.features.desktop.greeter
    modules.nixos.features.desktop.keyring
  ];

  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
}
