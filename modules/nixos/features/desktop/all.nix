{ modules, ... }:

{
  imports = [
    modules.nixos.features.desktop.audio
    modules.nixos.features.desktop.applications
    modules.nixos.features.desktop.cosmic
    modules.nixos.features.desktop.fonts
  ];
}
