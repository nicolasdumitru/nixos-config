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
    hosts.turing.tailscale
    hardware.rog-zephyrus-g16
    disko.rog-zephyrus-g16
    modules.nixos
  ];

  modules = {
    profiles.laptop.enable = true;

    desktop = {
      audio.enable = true;
      applications.enable = true;
      cosmic.enable = true;
      gnome.enable = true;
      fonts.enable = true;
      greeter = "cosmic-greeter";
    };

    android-studio.enable = true;
    asus-laptop.enable = true;
    development.enable = true;
    disks-filesystems.enable = true;
    gpu-monitor.enable = true;
    network-tools.enable = true;
    nvidia.enable = true;
    shell.enable = true;
    ti-nspire.enable = true;
    virtualization.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath;
    };
    users.nick = {
      imports = [ modules.homeManager ];

      modules = {
        dotfiles.enable = true;
        neovim.enable = true;
        cli-tools.enable = true;
        development.enable = true;
        zsh.enable = true;
      };

      home.username = "nick";
      home.homeDirectory = "/home/nick";

      # Home Manager compatibility baseline from the initial migration. Do not
      # change it during routine upgrades.
      home.stateVersion = "26.05";
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
