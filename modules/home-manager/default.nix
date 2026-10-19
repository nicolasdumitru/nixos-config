{ inputs }:

{
  cliTools = ./cli-tools.nix;
  development = import ./development.nix { inherit inputs; };
  dotfiles = import ./dotfiles;
  neovim = ./neovim.nix;
}
