{
  disko,
  hardware,
  hosts,
  modules,
  ...
}:

{
  imports = [
    hosts.turing.common
    hardware.rog-zephyrus-g16
    disko.rog-zephyrus-g16
    modules.nixos.profiles.bootstrap
  ];
}
