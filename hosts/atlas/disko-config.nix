let
  diskName = "vps-atlas";
in
{
  disko.devices.disk."${diskName}" = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions.ESP = {
        priority = 1;
        name = "ESP";
        start = "1M";
        end = "128M";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      partitions.root = {
        size = "100%";
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
              swap.swapfile.size = "32G";
            };
          };
          mountpoint = "/partition-root";

          swap.swapfile.size = "32G";
        };
      };
    };
  };
}
