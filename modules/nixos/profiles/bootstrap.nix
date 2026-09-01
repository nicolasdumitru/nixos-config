{
  modules,
  pkgs,
  ...
}:

{
  imports = [ modules.nixos.profiles.base ];

  # Limit only builds performed while the bootstrap generation is active.
  # The full configuration intentionally leaves normal parallelism unchanged.
  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  environment.systemPackages = [ pkgs.nano ];
}
