# List available recipes
list:
    @just --list

# Update the lockfile and commit it
update:
    nix flake update --commit-lock-file

# Rebuild the system
switch:
    nixos-rebuild --use-remote-sudo --flake ".#hermes" switch

format:
    nixfmt $(fd "." --full-path "$(git rev-parse --show-toplevel)")
