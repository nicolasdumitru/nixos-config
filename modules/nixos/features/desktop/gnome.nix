{ modules, ... }:

{
  imports = [
    modules.nixos.features.desktop.greeter
    modules.nixos.features.desktop.keyring
  ];

  services.desktopManager.gnome.enable = true;
}
