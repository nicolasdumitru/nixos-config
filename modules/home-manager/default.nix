{ inputs }:

{
  cliTools = ./cli-tools.nix;
  development = import ./development.nix { inherit inputs; };
  dotfiles = import ./dotfiles;
  neovimConfig = ./neovim-config.nix;
  neovimPackages = ./neovim-packages.nix;
}
