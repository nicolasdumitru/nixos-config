{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.ti-nspire;
in
{
  options.modules.ti-nspire = {
    enable = mkEnableOption "TI-Nspire calculator support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      google-chrome
    ];

    services.udev.extraRules = ''
      # TI-Nspire CX and older
      SUBSYSTEM=="usb", ATTR{idVendor}=="0451", ATTR{idProduct}=="e012", ENV{ID_PDA}="1"
      # TI-Nspire CX II, including CX II-T CAS
      SUBSYSTEM=="usb", ATTR{idVendor}=="0451", ATTR{idProduct}=="e022", ENV{ID_PDA}="1"
    '';
  };
}
