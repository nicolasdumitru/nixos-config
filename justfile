# The default recipe is always the first recipe in the justfile

# The recipe to run when just is invoked without a recipe
default: list

# List available recipes
list:
    @just --list

# Install NixOS on a new machine
install host:
    sudo nix --experimental-features "nix-command flakes" \
        run github:nix-community/disko/latest -- --mode destroy,format,mount \
        {{hosts}}/{{host}}/disko-config.nix
    sudo nixos-generate-config --no-filesystems --root /mnt
    -cp -i \
        /mnt/etc/nixos/hardware-configuration.nix \
        {{hosts}}/{{host}}/hardware-configuration.nix
    -git add {{hosts}}/{{host}}/hardware-configuration.nix
    sudo nixos-install --flake ".#{{host}}" --no-root-password
hosts := justfile_directory() + "/hosts"

# Reconfigure the system to match this configuration flake
rebuild operation=rebuild_op host=hostname:
    nixos-rebuild --use-remote-sudo --flake ".#{{host}}" {{operation}} --fallback
rebuild_op := 'switch'
hostname := `hostname`

# Delete Nix(OS) generations older than period
collect-garbage period='3d' operation=rebuild_op: && (rebuild operation)
    nix-collect-garbage --delete-older-than {{period}}
    sudo nix-collect-garbage --delete-older-than {{period}}
alias gc := collect-garbage

# Update the lockfile and commit it
update:
    nix flake update --commit-lock-file

# Format all Nix files
format:
    nixfmt $(fd '\.nix' --full-path "$(git rev-parse --show-toplevel)")
alias fmt := format
