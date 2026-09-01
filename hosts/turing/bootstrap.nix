{ ... }:

{
  imports = [
    ./common.nix
    ../../hardware/rog-zephyrus-g16.nix
    ../../disko/turing.nix
    ../../modules/nixos/profiles/bootstrap.nix
  ];
}
