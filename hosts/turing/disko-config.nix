{ lib, ... }:
let
  diskName = "zephyrus-ssd";
  configPath = /etc/nixos/disk-config.json;
  hasConfig = builtins.pathExists configPath;
  diskConfig = if hasConfig then builtins.fromJSON (builtins.readFile configPath) else null;
in
{
  disko.devices.disk."${diskName}" = {
    type = "disk";
    # During installation, this device path is used.
    # For a running system (rebuilds), this value is largely ignored by disko's module system
    # as it relies on the generated fileSystems config which uses labels/UUIDs.
    device = if hasConfig then diskConfig.device else "/dev/disk/by-id/REQUIRED_ONLY_FOR_INSTALLATION";
    content = {
      type = "gpt";
      partitions.ESP = {
        size = "512M";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      partitions.luks = {
        size = "100%";
        content = {
          type = "luks";
          name = "luks-${diskName}";
          settings.allowDiscards = true;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/swap" = {
                mountpoint = "/.swapvol";
                swap.swapfile.size = "64G";
              };
            };
          };
        };
      };
    };
  };
}
