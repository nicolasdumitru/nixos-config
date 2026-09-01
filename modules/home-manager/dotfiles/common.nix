{ ... }:

let
  managed = source: {
    inherit source;
    force = true;
  };
in
{
  # This is the Home Manager compatibility baseline from the initial migration.
  # Do not update it with routine Home Manager upgrades; consult the release notes
  # first because changing it can alter stateful defaults.
  home.stateVersion = "26.05";

  home.file = {
    ".bash_profile" = managed ../../../dotfiles/.bash_profile;
    ".bashrc" = managed ../../../dotfiles/.bashrc;
    ".ideavimrc" = managed ../../../dotfiles/.ideavimrc;
  };

  xdg.configFile = {
    "bat/config" = managed ../../../dotfiles/.config/bat/config;
    "ghostty/config.ghostty" = managed ../../../dotfiles/.config/ghostty/config.ghostty;
    "lf/lfrc" = managed ../../../dotfiles/.config/lf/lfrc;
    "readline/inputrc" = managed ../../../dotfiles/.config/readline/inputrc;
    "ripgrep/ripgreprc" = managed ../../../dotfiles/.config/ripgrep/ripgreprc;
    "starship.toml" = managed ../../../dotfiles/.config/starship.toml;
    "wget/wgetrc" = managed ../../../dotfiles/.config/wget/wgetrc;
    "zed/keymap.json" = managed ../../../dotfiles/.config/zed/keymap.json;
    "zed/settings.json" = managed ../../../dotfiles/.config/zed/settings.json;
  };
}
