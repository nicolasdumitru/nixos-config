{ pkgs, ... }:

{
  # Interactive behavior is owned by dotfiles/.bashrc.
  environment.systemPackages = [ pkgs.starship ];
}
