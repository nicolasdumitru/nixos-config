# List available recipes
list:
    @just --list

# Update the lockfile and commit it
update:
    nix flake update --commit-lock-file

# Build and activate the new configuration
switch:
    nixos-rebuild --use-remote-sudo --flake ".#hermes" switch

# Collect garbage
gc period='3d': && switch
    nix-collect-garbage --delete-older-than {{period}}
    sudo nix-collect-garbage --delete-older-than {{period}}

format:
    nixfmt $(fd "." --full-path "$(git rev-parse --show-toplevel)")
