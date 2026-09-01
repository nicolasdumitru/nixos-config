{ modules, ... }:

{
  # The package wrapper deliberately leaves startup discovery enabled, so this
  # native file is the single source of truth for Neovim behavior.
  xdg.configFile."nvim/init.lua" = {
    source = modules.files.dotfiles + "/.config/nvim/init.lua";
    force = true;
  };
}
