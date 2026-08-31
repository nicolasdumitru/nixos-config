# The default recipe is always the first recipe in the justfile.
default: list

flake := "path:" + justfile_directory()

list:
    @just --list

# Destructive: install the lightweight bootstrap system on an explicit disk.
# Prefer a stable /dev/disk/by-id path for DEVICE.
install host device:
    sudo nix --option max-jobs 2 --option cores 2 run "{{flake}}#disko-install" -- \
        --option max-jobs 2 --option cores 2 \
        --write-efi-boot-entries \
        --flake "{{flake}}#{{host}}-bootstrap" \
        --disk system "{{device}}"

# Reconfigure the normal full system.
rebuild operation=rebuild_op host=hostname:
    nixos-rebuild --sudo --flake "{{flake}}#{{host}}" {{operation}}

# Reconfigure only the lightweight bootstrap system.
rebuild-bootstrap operation=rebuild_op host=hostname:
    nixos-rebuild --sudo --flake "{{flake}}#{{host}}-bootstrap" {{operation}}

rebuild_op := 'switch'
hostname := `hostname`

collect-garbage period='3d' operation=rebuild_op: && (rebuild operation)
    nix-collect-garbage --delete-older-than {{period}}
    sudo nix-collect-garbage --delete-older-than {{period}}
alias gc := collect-garbage

update:
    nix flake update --commit-lock-file

format:
    nix fmt
    stylua --verify dotfiles/.config/nvim/init.lua
alias fmt := format
