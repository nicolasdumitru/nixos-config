{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.android-studio;
in
{
  options.modules.android-studio.enable = lib.mkEnableOption "Android Studio";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-studio
      android-tools
    ];

    # Studio's default SDK location; lets tools run outside the IDE find it too.
    environment.sessionVariables.ANDROID_HOME = "$HOME/Android/Sdk";

    # Studio runs in an FHS environment, but the SDK binaries it downloads also
    # run outside of it, such as `./gradlew` or `emulator` from a plain shell.
    # These are the libraries the SDK links against without bundling them, beyond
    # those nix-ld always provides.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        dbus
        expat
        libbsd
        libdrm
        libgbm
        libGL
        libice
        libpng
        libpulseaudio
        libsm
        libx11
        libxcb
        libxext
        libxi
        libxkbfile
        ncurses5
        nspr
        nss
      ];
    };

    # The emulator's bundled Vulkan loader has no NixOS paths compiled in, so
    # outside the FHS environment it fails to find the host's GPU drivers.
    environment.sessionVariables.XDG_DATA_DIRS = [ "/run/opengl-driver/share" ];

    # Hardware acceleration for the emulator.
    users.users.nick.extraGroups = [ "kvm" ];
  };
}
