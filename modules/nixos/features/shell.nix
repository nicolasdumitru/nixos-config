{ pkgs, ... }:

{
  # Interactive behavior is owned by dotfiles/.bashrc and dotfiles/.config/zsh/.zshrc.
  environment.systemPackages = [ pkgs.starship ];

  # Provides /etc/zshenv (NixOS environment), registers zsh in /etc/shells and
  # links completions from installed packages. Prompt, options and compinit are
  # left to the user's .zshrc.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
    setOptions = [ ];
  };

  users.users.nick.shell = pkgs.zsh;
}
