{ ... }:

{
  # Every module here only declares options under `modules.*` and does nothing
  # until a host enables it.
  imports = [
    ./profiles/laptop.nix
    ./profiles/bootstrap.nix
    ./profiles/server.nix
    ./features/android-studio.nix
    ./features/asus-laptop.nix
    ./features/desktop/audio.nix
    ./features/desktop/applications.nix
    ./features/desktop/cosmic.nix
    ./features/desktop/fonts.nix
    ./features/desktop/gnome.nix
    ./features/development.nix
    ./features/disks-filesystems.nix
    ./features/network-tools.nix
    ./features/nvidia.nix
    ./features/remote-unlock.nix
    ./features/peripherals/ti-nspire.nix
    ./features/shell.nix
    ./features/sql-server.nix
    ./features/ssh-server.nix
    ./features/virtualization.nix
    ./features/wake-on-lan.nix

    # Turned on by the modules above rather than by hosts directly.
    ./profiles/base.nix
    ./features/desktop/greeter.nix
    ./features/desktop/keyring.nix
    ./features/nix-config.nix
  ];
}
