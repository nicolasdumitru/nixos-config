{ inputs }:

{
  modules,
  pkgs,
  ...
}:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = modules.packageSets.development {
    inherit inputs pkgs;
  };
}
