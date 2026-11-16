{ inputs }:

{ ... }:

{
  # Every module here only declares options under `modules.*` and does nothing
  # until a home enables it.
  imports = [
    ./dotfiles/common.nix
    ./dotfiles/linux.nix
    ./neovim.nix
    ./cli-tools.nix
    (import ./development.nix { inherit inputs; })
    ./zsh.nix
  ];
}
