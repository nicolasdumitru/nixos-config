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
  # self.nixosModules.neovim may be imported through multiple module branches.
  # A stable key lets the NixOS module system deduplicate those imports.
  key = "nixos-config/neovim";

  options.modules.neovim.enable = lib.mkEnableOption "the configured Neovim editor";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Plugins are fetched and versioned by nixpkgs. customRC is Vimscript, so
      # this small bridge loads the real Lua configuration from this repository.
      configure = {
        customRC = ''lua dofile("${./init.lua}")'';

        packages.default = with pkgs.vimPlugins; {
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
    };

    # Runtime dependencies used by Neovim and its plugins.
    environment.systemPackages = with pkgs; [
      tree-sitter
      fd
      ripgrep
    ];
  };
}
