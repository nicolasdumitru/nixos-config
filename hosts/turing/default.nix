{ ... }:

{
  imports = [
    ./common.nix
    ../../hardware/rog-zephyrus-g16.nix
    ../../disko/turing.nix
    ../../nixos/profiles/laptop.nix
    ../../nixos/features/nvidia.nix
    ../../nixos/features/asus-laptop.nix
  ];

  # Preserve the full workstation's caches without making CUDA a GPU-driver
  # requirement or enabling a CUDA workload.
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
