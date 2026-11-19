# Hardware knowledge for the ASUS TUF F15; this is not a complete OS host.
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "vmd"
    "nvme"
    "usbhid"
    # TODO: confirm the wired network card's driver with `lspci -k` on the machine.
    # Realtek is assumed. Unlocking the disk over SSH during boot needs it here.
    "r8169"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;

  # TODO: before enabling `modules.nvidia` here, read the GPUs' bus IDs with
  # `lspci` on the machine (converted to decimal, as in rog-zephyrus-g16.nix)
  # and set `hardware.nvidia.prime.intelBusId` and `nvidiaBusId`.

}
