{ config, lib, ... }:

let
  cfg = config.modules.asus-laptop;
in
{
  options.modules.asus-laptop.enable = lib.mkEnableOption "ASUS laptop control (asusd)";

  config = lib.mkIf cfg.enable {
    services.asusd.enable = true;

    # Preserve the ROG Zephyrus G16's current state; supergfxd is intentionally disabled.
    services.supergfxd.enable = false;
  };
}
