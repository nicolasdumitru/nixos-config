{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.scanning;
in
{
  options.modules.scanning = {
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users to add to scanner and lp groups";
    };
    drivers = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "SANE backends to enable";
    };
  };

  config = {
    hardware.sane = {
      enable = true;
      extraBackends = cfg.drivers;
    };
    users.users = lib.mkMerge (
      map (user: {
        ${user}.extraGroups = lib.mkAfter [
          "scanner"
          "lp"
        ];
      }) cfg.users
    );
    environment.systemPackages = [ pkgs.simple-scan ];
  };
}
