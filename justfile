# List available recipes
list:
    @just --list

flake := justfile_directory()

# Update the lockfile
_update args="":
    nix flake update {{flake}} {{args}}

# Update the lockfile and commit it
update: (_update "--commit-lock-file")

# Rebuild the system
switch:
    nixos-rebuild --use-remote-sudo --flake "{{flake}}#hermes" switch
