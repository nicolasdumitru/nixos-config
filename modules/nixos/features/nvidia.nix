{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.nvidia;
in
{
  options.modules.nvidia.enable = lib.mkEnableOption "the NVIDIA driver with PRIME offload";

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      dynamicBoost.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime.offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
}
