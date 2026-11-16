{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.dotfiles;
  dotfiles = dotfilesPath;
  managed = source: {
    inherit source;
    force = true;
  };
in
{
  # The Linux-only part of `modules.dotfiles`; it has no option of its own.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    # Keep Linux-native files in their upstream formats. In particular, do not
    # enable the Home Manager MIME or user-dirs generators for these paths.
    xdg.configFile = {
      "mimeapps.list" = managed (dotfiles + "/.config/mimeapps.list");
      "user-dirs.dirs" = managed (dotfiles + "/.config/user-dirs.dirs");
      "user-dirs.locale" = managed (dotfiles + "/.config/user-dirs.locale");
    };
  };
}
