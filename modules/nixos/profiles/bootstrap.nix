{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.profiles.bootstrap;
in
{
  options.modules.profiles.bootstrap.enable =
    lib.mkEnableOption "the lightweight bootstrap system (includes the base profile)";

  config = lib.mkIf cfg.enable {
    modules.profiles.base.enable = true;

    # Limit only builds performed while the bootstrap generation is active.
    # The full configuration intentionally leaves normal parallelism unchanged.
    nix.settings = {
      max-jobs = 2;
      cores = 2;
    };

    environment.systemPackages = [ pkgs.nano ];
  };
}
