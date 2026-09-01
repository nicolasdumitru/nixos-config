{
  modules,
  pkgs,
  ...
}:

let
  neovim = modules.packageSets.neovim { inherit pkgs; };
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
