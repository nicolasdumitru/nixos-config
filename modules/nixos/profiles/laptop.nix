{
  lib,
  modules,
  ...
}:

{
  imports = [ modules.nixos.profiles.base ];

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
}
