{
  disko,
  dotfilesPath,
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
    modules.nixos.profiles.laptop
    modules.nixos.features.asusLaptop
    modules.nixos.features.cliTools
    modules.nixos.features.desktop.audio
    modules.nixos.features.desktop.applications
    modules.nixos.features.desktop.cosmic
    modules.nixos.features.desktop.fonts
    modules.nixos.features.development
    modules.nixos.features.disksFilesystems
    modules.nixos.features.gaming
    modules.nixos.features.neovim
    modules.nixos.features.networkTools
    modules.nixos.features.nvidia
    modules.nixos.features.peripherals.tiNspire
    modules.nixos.features.shell
    modules.nixos.features.virtualization
  ];

  modules.ti-nspire.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath modules;
    };
    users.nick = {
      imports = [
        modules.homeManager.dotfiles.common
        modules.homeManager.dotfiles.linux
        modules.homeManager.neovimConfig
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
