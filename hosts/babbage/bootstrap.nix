{
  disko,
  hardware,
  hosts,
  modules,
  ...
}:

{
  imports = [
    hosts.babbage.common
    hardware.tuf-f15
    disko.tuf-f15
    modules.nixos
  ];

  modules.profiles.bootstrap.enable = true;
}
