{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.scanning;
in
{
  options.modules.scanning = {
    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Users to add to scanner and lp groups";
    };

    drivers = mkOption {
      type = types.listOf types.package; # or types.path if strings are used? usually packages
      default = [ ];
      description = "SANE backends to enable";
    };
  };

  config = {
    hardware.sane = {
      enable = true;
      extraBackends = cfg.drivers;
    };

    users.users = mkMerge (
      map (user: {
        ${user} = {
          extraGroups = mkAfter [
            "scanner"
            "lp"
          ];
        };
      }) cfg.users
    );

    environment.systemPackages = with pkgs; [
      simple-scan
    ];
  };
}
