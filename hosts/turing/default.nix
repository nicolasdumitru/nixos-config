{
  pkgs,
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
    modules.nixos.features.androidStudio
    modules.nixos.features.asusLaptop
    modules.nixos.features.desktop.audio
    modules.nixos.features.desktop.applications
    modules.nixos.features.desktop.cosmic
    modules.nixos.features.desktop.fonts
    modules.nixos.features.desktop.gnome
    modules.nixos.features.development
    modules.nixos.features.disksFilesystems
    modules.nixos.features.networkTools
    modules.nixos.features.nvidia
    modules.nixos.features.peripherals.tiNspire
    modules.nixos.features.shell
    modules.nixos.features.sqlServer
    modules.nixos.features.virtualization
  ];

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath modules;
    };
    users.nick = {
      imports = [
        modules.homeManager.dotfiles.common
        modules.homeManager.dotfiles.linux
        modules.homeManager.neovim
        modules.homeManager.cliTools
        modules.homeManager.development
        modules.homeManager.zsh
      ];
      home.username = "nick";
      home.homeDirectory = "/home/nick";
    };
  };

  environment.systemPackages = with pkgs; [
    kopia
    kopia-ui
  ];

  systemd.user.services.kopia-snapshot = {
    description = "Kopia snapshot";
    unitConfig.ConditionUser = "nick";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kopia}/bin/kopia snapshot create --all";
    };
  };

  systemd.user.timers.kopia-snapshot = {
    wantedBy = [ "timers.target" ];
    unitConfig.ConditionUser = "nick";
    timerConfig = {
      OnCalendar = "*-*-* 00/6:00:00";
      Persistent = true;
    };
  };

  modules.android-studio.enable = true;
  modules.ti-nspire.enable = true;
  modules.greeter = "cosmic-greeter";

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
