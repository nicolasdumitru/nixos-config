# The console installer ISO.
{
  hosts,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    hosts.lovelace.common
  ];

  image.baseName = lib.mkForce "lovelace-minimal-${pkgs.stdenv.hostPlatform.system}";
}
