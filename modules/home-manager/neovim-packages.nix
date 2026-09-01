{
  modules,
  pkgs,
  ...
}:

let
  neovim = modules.packageSets.neovim { inherit pkgs; };
in
{
  home.packages = neovim.all;
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
