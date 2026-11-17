{ config, lib, ... }:

let
  cfg = config.modules.editor;
in
{
  options.modules.editor.enable = lib.mkEnableOption "Neovim as the system-wide editor";

  # A plain Neovim for every user, including root. Users with the Home Manager
  # Neovim get that one instead: their profile comes first in PATH.
  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      # Language providers are not needed without plugins.
      withPython3 = false;
      withRuby = false;
    };
  };
}
