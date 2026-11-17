# Git
Always ask for permission before committing unless it was given to you explicitly.
Always ask for permsission before pushing the `main` or `dev` branches. You can push feature branches you create at will.

# Style
Always format the entire repository before committing anything using treefmt: run `just fmt` (or `nix fmt`, or `treefmt` inside the development shell). All three run the same treefmt configuration from `flake.nix`, which formats Nix, Lua, and Python files. Then review what the formatter changed and include those changes in the commit. `nix flake check` fails if anything is left unformatted.

If you change the formatter setup (the treefmt configuration or the `checks.formatting` check in `flake.nix`, or the `format` recipe in the `justfile`), update this section in the same change so it stays accurate.