# The default recipe is always the first recipe in the justfile

# The recipe to run when just is invoked without a recipe
default: list

# List available recipes
list:
    @just --list

# Update the lockfile and commit it
update:
    nix flake update --commit-lock-file

# Reconfigure the system to match this configuration flake
rebuild operation=rebuild_op:
    nixos-rebuild --use-remote-sudo --flake ".#hermes" {{operation}}
rebuild_op := 'switch'

# Delete Nix(OS) generations older than period
collect-garbage period='3d' operation=rebuild_op: && (rebuild operation)
    nix-collect-garbage --delete-older-than {{period}}
    sudo nix-collect-garbage --delete-older-than {{period}}
alias gc := collect-garbage

# Format all Nix files
format:
    nixfmt $(fd '\.nix' --full-path "$(git rev-parse --show-toplevel)")
alias fmt := format
