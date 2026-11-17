# The default recipe is always the first recipe in the justfile.
default: list

flake := "path:" + justfile_directory()

list:
    @just --list

# Destructive: install the lightweight bootstrap system on an explicit disk.
# Prefer a stable /dev/disk/by-id path for DEVICE.
install host device: (_install host device "")

# Like `install`, for installation media without flakes enabled, such as the
# official NixOS ISOs.
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
# it. ISO is an image file, or graphical (the default) or minimal to build that
# installer first. Prefer a stable /dev/disk/by-id path for DEVICE.
burn device iso="graphical":
    #!/usr/bin/env bash
    set -euo pipefail
    device=$(realpath -- "{{device}}")
    if [[ ! -b $device ]]; then
        echo "{{device}} is not a block device" >&2
        exit 1
    fi
    read -r type transport removable < <(lsblk --nodeps --noheadings --output TYPE,TRAN,RM -- "$device")
    if [[ $type != disk ]]; then
        echo "$device is a $type, not a whole disk" >&2
        exit 1
    fi
    if [[ $transport != usb && $removable != 1 ]]; then
        echo "$device is neither a USB nor a removable disk; refusing to overwrite it" >&2
        exit 1
    fi
    if lsblk --noheadings --output MOUNTPOINTS -- "$device" | grep -q '[^[:space:]]'; then
        echo "$device has mounted partitions; unmount them first:" >&2
        lsblk --output NAME,SIZE,MOUNTPOINTS -- "$device" >&2
        exit 1
    fi
    iso="{{iso}}"
    if [[ $iso == graphical || $iso == minimal ]]; then
        iso=$(nix build --no-link --print-out-paths "{{flake}}#installer-iso-$iso")
        iso=$(echo "$iso"/iso/*.iso)
    fi
    if [[ ! -f $iso ]]; then
        echo "$iso is not a file" >&2
        exit 1
    fi
    size=$(stat --dereference --format=%s -- "$iso")
    if (( size > $(lsblk --nodeps --noheadings --bytes --output SIZE -- "$device") )); then
        echo "the image does not fit on $device" >&2
        exit 1
    fi
    echo "Image:  $iso ($(numfmt --to=iec "$size"))"
    lsblk --output NAME,MODEL,SIZE,TRAN -- "$device"
    read -r -p "Everything on $device will be erased. Type 'yes' to continue: " answer
    if [[ $answer != yes ]]; then
        echo "Aborted."
        exit 1
    fi
    sudo dd if="$iso" of="$device" bs=4M conv=fsync oflag=direct status=progress
    sync
    echo "Verifying..."
    sudo cmp --bytes="$size" -- "$iso" "$device"
    echo "Done: $device holds the image and can be removed."

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
