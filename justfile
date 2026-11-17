# The default recipe is always the first recipe in the justfile.
default: list

flake := "path:" + justfile_directory()

list:
    @just --list

# Destructive: install the lightweight bootstrap system on an explicit disk.
# Prefer a stable /dev/disk/by-id path for DEVICE.
[doc("Destructive: install a host's bootstrap system on a disk")]
install host device: (_install host device "")

# Like `install`, for installation media without flakes enabled, such as the
# official NixOS ISOs.
[doc("Like install, from installation media without flakes enabled")]
install-compat host device: (_install host device "--extra-experimental-features 'nix-command flakes'")

[private]
_install host device nix_options:
    #!/usr/bin/env bash
    set -euo pipefail
    nix_options=({{nix_options}})
    configuration="{{flake}}#nixosConfigurations.{{host}}-bootstrap"
    # The host's Disko layout names its disk; disko-install maps that name.
    disk=$(nix "${nix_options[@]}" eval --raw "$configuration.config.disko.devices.disk" \
        --apply 'disks: builtins.concatStringsSep " " (builtins.attrNames disks)')
    if [[ -z $disk || $disk == *" "* ]]; then
        echo "expected exactly one disk in the {{host}} layout, found: ${disk:-none}" >&2
        exit 1
    fi
    sudo nix "${nix_options[@]}" --option max-jobs 2 --option cores 2 \
        run "{{flake}}#disko-install" -- \
        --option max-jobs 2 --option cores 2 \
        --write-efi-boot-entries \
        --flake "{{flake}}#{{host}}-bootstrap" \
        --disk "$disk" "{{device}}"

# Build an installer ISO: graphical (COSMIC), minimal (console), or both.
# Each lands in ./result-<variant>/iso.
[doc("Build an installer ISO: graphical (default), minimal, or both")]
iso variant="graphical":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{variant}}" in
        graphical | minimal) variants=("{{variant}}") ;;
        both) variants=(graphical minimal) ;;
        *)
            echo "unknown variant {{variant}}; use graphical, minimal, or both" >&2
            exit 1
            ;;
    esac
    for variant in "${variants[@]}"; do
        nix build --out-link "result-$variant" "{{flake}}#installer-iso-$variant"
        echo "$variant: $(echo "result-$variant"/iso/*.iso)"
    done

# Destructive: write the installer ISO to a USB stick, replacing everything on
# it. ISO is graphical (the default) or minimal for the installer `just iso`
# built, or an image file. Prefer a stable /dev/disk/by-id path for DEVICE.
[doc("Destructive: write an installer ISO to a USB stick")]
burn device iso="graphical":
    @case "{{iso}}" in graphical | minimal) ;; *) [ -f "{{iso}}" ] || { echo "invalid input: {{iso}}" >&2; exit 1; } ;; esac
    sudo nix run "{{flake}}#burn" -- "{{device}}" "{{iso}}"

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
alias fmt := format
