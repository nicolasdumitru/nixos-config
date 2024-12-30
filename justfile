# The default recipe is always the first recipe in the justfile

# The recipe to run when just is invoked without a recipe
default: list

# List available recipes
list:
    @just --list

# Update the lockfile and commit it
update:
    nix flake update --commit-lock-file

# Build and activate the new configuration
switch:
    nixos-rebuild --use-remote-sudo --flake ".#hermes" switch

# Delete Nix(OS) generations older than period
collect-garbage period='3d': && switch
    nix-collect-garbage --delete-older-than {{period}}
    sudo nix-collect-garbage --delete-older-than {{period}}
alias gc := collect-garbage

# Format all Nix files
format:
    nixfmt $(fd '\.nix' --full-path "$(git rev-parse --show-toplevel)")
alias fmt := format
