{
  vboxUsers ? [ ],
}: # Accept a list of usernames

{
  lib,
  ...
}:

{
  boot.kernelParams = lib.mkBefore [
    "kvm.enable_virt_at_load=0"
  ];

  # VirtualBox
  virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  users.groups.vboxusers.members = vboxUsers;
}
