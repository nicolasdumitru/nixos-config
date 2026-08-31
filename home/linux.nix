{ ... }:

let
  managed = source: {
    inherit source;
    force = true;
  };
in
{
  # Keep Linux-native files in their upstream formats. In particular, do not
  # enable the Home Manager MIME or user-dirs generators for these paths.
  xdg.configFile = {
    "lf/lfrc" = managed ../dotfiles/.config/lf/lfrc;
    "mimeapps.list" = managed ../dotfiles/.config/mimeapps.list;
    "user-dirs.dirs" = managed ../dotfiles/.config/user-dirs.dirs;
    "user-dirs.locale" = managed ../dotfiles/.config/user-dirs.locale;
  };
}
