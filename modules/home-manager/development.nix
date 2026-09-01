{ inputs }:

{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = import ../../lib/package-sets/development.nix {
    inherit inputs pkgs;
  };
}
