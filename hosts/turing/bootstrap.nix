{ ... }:

{
  imports = [
    ./common.nix
    ../../hardware/rog-zephyrus-g16.nix
    ../../disko/turing.nix
    ../../nixos/profiles/bootstrap.nix
  ];
}
