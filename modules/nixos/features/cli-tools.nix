{
  modules,
  pkgs,
  ...
}:

{
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  environment.systemPackages = modules.packageSets.cliTools {
    inherit pkgs;
  };
}
