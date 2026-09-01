{
  inputs,
  modules,
  pkgs,
  ...
}:

{
  systemd.coredump.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.nix-ld.enable = true;

  environment.systemPackages = modules.packageSets.development {
    inherit inputs pkgs;
  };
}
