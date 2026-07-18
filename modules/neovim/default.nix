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
                bash
                c
                cpp
                css
                dockerfile
                git_config
                git_rebase
                gitattributes
                gitcommit
                gitignore
                go
                gomod
                gosum
                gowork
                html
                javascript
                json
                lua
                markdown
                markdown_inline
                nix
                python
                regex
                rust
                toml
                typescript
                vim
                vimdoc
                yaml
              ]
            ))

            plenary-nvim
            telescope-nvim

            nvim-lspconfig
            nvim-cmp
            cmp-buffer
            cmp-nvim-lsp
            cmp_luasnip
            luasnip
            friendly-snippets

            gitsigns-nvim
            lualine-nvim
            which-key-nvim
            vim-sleuth
            gruvbox-nvim
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
