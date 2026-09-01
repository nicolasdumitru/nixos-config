{ modules, ... }:

{
  imports = [
    modules.hosts.turing.common
    modules.hardware.rog-zephyrus-g16
    modules.disko.rog-zephyrus-g16
    modules.nixos.profiles.bootstrap
  ];
}
