{ pkgs, ... }:

{
  # Interactive behavior is owned by dotfiles/.bashrc and dotfiles/.config/zsh/.zshrc;
  # the shell programs themselves are installed by Home Manager. NixOS only
  # provides the environment (/etc/profile, /etc/zshenv: PATH, NIX_PATH, ...).
  # The dotfiles skip the system-wide interactive files (/etc/zshrc via
  # GLOBAL_RCS, /etc/bashrc via NOSYSBASHRC), so nothing NixOS puts there,
  # such as its default aliases, reaches the shells.

  # Registers zsh in /etc/shells, writes /etc/zshenv and links completions from
  # installed packages into the system profile.
  programs.zsh.enable = true;

  # Puts the bash-completion loader at /run/current-system/sw/share/bash-completion/,
  # where dotfiles/.bashrc loads it from.
  environment.systemPackages = [ pkgs.bash-completion ];

  users.users.nick.shell = pkgs.zsh;
}
