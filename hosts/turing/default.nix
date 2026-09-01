{ ... }:

{
  imports = [
    ./common.nix
    ../../hardware/rog-zephyrus-g16.nix
    ../../disko/turing.nix
    ../../modules/nixos/profiles/laptop.nix
    ../../modules/nixos/features/asus-laptop.nix
    ../../modules/nixos/features/cli-tools.nix
    ../../modules/nixos/features/desktop/audio.nix
    ../../modules/nixos/features/desktop/applications.nix
    ../../modules/nixos/features/desktop/cosmic.nix
    ../../modules/nixos/features/desktop/fonts.nix
    ../../modules/nixos/features/development.nix
    ../../modules/nixos/features/disks-filesystems.nix
    ../../modules/nixos/features/gaming.nix
    ../../modules/nixos/features/neovim.nix
    ../../modules/nixos/features/network-tools.nix
    ../../modules/nixos/features/nvidia.nix
    ../../modules/nixos/features/peripherals/ti-nspire.nix
    ../../modules/nixos/features/shell.nix
    ../../modules/nixos/features/virtualization.nix
  ];

  modules.ti-nspire.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    users.nick = {
      imports = [
        ../../modules/home-manager/dotfiles/common.nix
        ../../modules/home-manager/dotfiles/linux.nix
        ../../modules/home-manager/neovim-config.nix
      ];
      home.username = "nick";
      home.homeDirectory = "/home/nick";
    };
  };

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
