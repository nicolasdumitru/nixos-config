{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.neovim;
in
{
  options.modules.neovim.enable = lib.mkEnableOption "the configured Neovim editor";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Nix provisions plugins; Home Manager deploys the native init.lua.
      configure.packages.default = with pkgs.vimPlugins; {
        start = [
          (nvim-treesitter.withPlugins (
            parsers: with parsers; [
              asm
              bash
              bibtex
              c
              cpp
              git_config
              git_rebase
              gitattributes
              gitcommit
              gitignore
              haskell
              just
              latex
              lua
              make
              markdown
              markdown_inline
              nix
              python
              query
              rust
              vim
              vimdoc
            ]
          ))
          flash-nvim
          plenary-nvim
          telescope-nvim
          telescope-file-browser-nvim
          nvim-web-devicons
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      tree-sitter
      fd
      ripgrep
    ];
  };
}
