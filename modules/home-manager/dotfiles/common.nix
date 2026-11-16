{
  config,
  dotfilesPath,
  lib,
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
  options.modules.dotfiles.enable = lib.mkEnableOption "the repository's dotfiles";

  config = lib.mkIf cfg.enable {
    home.file = {
      ".bash_profile" = managed (dotfiles + "/.bash_profile");
      ".bashrc" = managed (dotfiles + "/.bashrc");
      ".ideavimrc" = managed (dotfiles + "/.ideavimrc");
      ".zshenv" = managed (dotfiles + "/.zshenv");
    };

    xdg.configFile = {
      "bat/config" = managed (dotfiles + "/.config/bat/config");
      "ghostty/config.ghostty" = managed (dotfiles + "/.config/ghostty/config.ghostty");
      "lf/lfrc" = managed (dotfiles + "/.config/lf/lfrc");
      "readline/inputrc" = managed (dotfiles + "/.config/readline/inputrc");
      "ripgrep/ripgreprc" = managed (dotfiles + "/.config/ripgrep/ripgreprc");
      "wget/wgetrc" = managed (dotfiles + "/.config/wget/wgetrc");
      "zsh/.zprofile" = managed (dotfiles + "/.config/zsh/.zprofile");
      "zsh/.zshrc" = managed (dotfiles + "/.config/zsh/.zshrc");
    };
  };
}
