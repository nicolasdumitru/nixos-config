{ ... }:

{
  imports = [
    ./common.nix
    ../../hardware/turing.nix
    ../../disko/turing.nix
    ../../nixos/profiles/bootstrap.nix
  ];
}
