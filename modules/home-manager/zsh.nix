{ pkgs, ... }:

{
  # Interactive behavior is owned by dotfiles/.config/zsh/.zshrc; this module
  # only provides the programs it needs and the Nix store paths of its plugins.
  home.packages = with pkgs; [
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship
    direnv
  ];

  # Sourced at the end of .zshrc. Syntax highlighting must be loaded last.
  xdg.configFile."zsh/plugins.zsh".text = ''
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';
}
