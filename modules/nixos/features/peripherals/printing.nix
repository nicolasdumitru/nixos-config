{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.printing;
in
{
  options.modules.printing.drivers = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Printing drivers to enable";
  };

  config.services.printing = {
    enable = true;
    drivers = lib.mkAfter cfg.drivers;
  };
}
