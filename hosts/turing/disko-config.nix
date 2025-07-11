let
  diskName = "zephyrus-ssd";
in
{
  disko.devices.disk."${diskName}" = {
    type = "disk";
    device = "/dev/nvme0n1";
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
