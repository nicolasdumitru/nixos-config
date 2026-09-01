{ pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  environment.systemPackages = import ../../../lib/package-sets/cli-tools.nix {
    inherit pkgs;
  };
}
