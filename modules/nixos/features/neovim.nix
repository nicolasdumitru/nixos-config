{ pkgs, ... }:

let
  neovim = import ../../../lib/package-sets/neovim.nix { inherit pkgs; };
in
{
  environment.systemPackages = neovim.all;
  # Preserve discovery of runtime files contributed by other system packages.
  environment.pathsToLink = [ "/share/nvim" ];
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
