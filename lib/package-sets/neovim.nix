{ pkgs }:

let
  plugins = with pkgs.vimPlugins; [
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

  package = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    inherit plugins;
    extraName = "-configured";
    viAlias = true;
    vimAlias = true;

    # Plugins belong to the wrapper, while startup configuration remains the
    # native XDG init.lua deployed by Home Manager.
    autoconfigure = false;
    wrapRc = false;
  };

  runtimePackages = with pkgs; [
    tree-sitter
    fd
    ripgrep
  ];
in
{
  inherit package runtimePackages;
  all = [ package ] ++ runtimePackages;
}
