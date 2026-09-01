{
  modules,
  pkgs,
  ...
}:

{
  home.packages = modules.packageSets.cliTools { inherit pkgs; };
}
