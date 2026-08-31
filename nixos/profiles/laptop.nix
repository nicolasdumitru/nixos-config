{
  lib,
  ...
}:

{
  imports = [
    ./base.nix
    ../features/shell.nix
    ../features/cli-tools.nix
    ../features/desktop.nix
    ../features/gaming.nix
    ../features/development
    ../features/neovim.nix
    ../features/virtualization.nix
    ../features/network-tools.nix
    ../features/disks-filesystems.nix
    ../features/peripherals/ti-nspire.nix
  ];

  boot = {
    plymouth = {
      enable = true;
      theme = "bgrt";
    };
    consoleLogLevel = 4;
    kernelParams = lib.mkBefore [
      "quiet"
      "splash"
      "mem_sleep_default=deep"
    ];
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };

  services.libinput.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp.enable = lib.mkForce false;
  powerManagement.powertop.enable = lib.mkForce false;
  services.tuned = {
    enable = true;
    ppdSupport = true;
    ppdSettings.profiles = {
      balanced = "balanced";
      performance = "throughput-performance";
      power-saver = "powersave";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  modules.neovim.enable = true;
  modules.ti-nspire.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    users.nick = {
      imports = [
        ../../home/common.nix
        ../../home/linux.nix
      ];
      home.username = "nick";
      home.homeDirectory = "/home/nick";
    };
  };
}
