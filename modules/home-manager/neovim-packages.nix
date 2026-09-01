{ pkgs, ... }:

let
  neovim = import ../../lib/package-sets/neovim.nix { inherit pkgs; };
in
{
  home.packages = neovim.all;
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
