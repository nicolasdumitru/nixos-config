{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.zsh;
in
{
  options.modules.zsh.enable = lib.mkEnableOption "zsh with its plugins and prompt";

  config = lib.mkIf cfg.enable {
    # Interactive behavior is owned by dotfiles/.config/zsh/.zshrc; this module
    # only provides the programs it needs and the Nix store paths of its plugins.
    home.packages = with pkgs; [
      zsh
      zsh-autosuggestions
      zsh-syntax-highlighting
      direnv
    ];

    # Sourced at the end of .zshrc. Syntax highlighting must be loaded last.
    xdg.configFile."zsh/plugins.zsh".text = ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '';

    # The shells' dotfiles run `zoxide init` themselves.
    programs.zoxide = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };

    # dotfiles/.config/starship.toml stays the source of truth (and stays usable
    # as a plain dotfile); Home Manager regenerates it and validates it against
    # starship's schema at build time. The shells' dotfiles run `starship init`
    # themselves, so the Home Manager shell integrations stay off.
    programs.starship = {
      enable = true;
      settings = lib.importTOML (dotfilesPath + "/.config/starship.toml");
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
  };
}
