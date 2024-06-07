#!/usr/bin/env bash

set -e

DISK=$1

LUKS_DEVICE="/dev/mapper/encrypted"

# Partition
parted "${DISK}" -- mklabel gpt
parted "${DISK}" -- mkpart ESP fat32 1MB 512MB
parted "${DISK}" -- set 1 esp on
parted "${DISK}" -- mkpart root ext4 512MB -32GB
parted "${DISK}" -- mkpart swap linux-swap -32GB 100%

mkdir -p /mnt

# Encrypt root
cryptsetup --label luksdev --verify-passphrase luksFormat "${DISK}p2"
cryptsetup open "${DISK}p2" encrypted

mkfs.btrfs -L nixos "${LUKS_DEVICE}"

mount -t btrfs "${LUKS_DEVICE}" /mnt

btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/.snapshots
btrfs subvolume create /mnt/log

umount /mnt

mount -o subvol=root,compress=zstd,noatime /dev/disk/by-label/nixos /mnt

mkdir -p /mnt/home
mount -o subvol=home,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/home

mkdir -p /mnt/nix
mount -o subvol=nix,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/nix

mkdir -p /mnt/.snapshots
mount -o subvol=.snapshots,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/.snapshots

mkdir -p /mnt/var/log
mount -o subvol=log,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/var/log

# swap
mkswap -L swap "${DISK}p3"

# bootloader
mkfs.vfat -F 32 -n BOOT "${DISK}p1" &&
    mkdir -p /mnt/boot && sleep 1 &&
    while [ ! -e /dev/disk/by-label/BOOT ]; do sleep 1; done &&
    mount -o umask=022 /dev/disk/by-label/BOOT /mnt/boot

echo "SSD prepared SUCCESSFULLY"
echo "Proceed with the next installation steps."
