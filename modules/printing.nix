{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.printing;
in
{
  options.modules.printing = {
    drivers = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Printing drivers to enable";
    };
  };

  config = {
    services.printing = {
      enable = true;
      drivers = mkAfter cfg.drivers;
    };
  };
}
