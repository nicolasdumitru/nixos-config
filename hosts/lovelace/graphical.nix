# The graphical installer ISO, with the COSMIC desktop set up as on Turing.
{
  hosts,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    hosts.lovelace.common
  ];

  image.baseName = lib.mkForce "lovelace-graphical-${pkgs.stdenv.hostPlatform.system}";
  isoImage.edition = "cosmic";

  modules.desktop = {
    cosmic.enable = true;
    audio.enable = true;
    fonts.enable = true;
    applications.enable = true;
  };
  modules.disks-filesystems.enable = true;

  # Log straight into the desktop, as the console installer does.
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
}
