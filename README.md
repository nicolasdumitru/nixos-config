# NixOS, Home Manager, and Dotfiles

This repository contains the complete `turing` system configuration, a small
bootstrap configuration, reusable NixOS features, physical hardware facts,
Disko layouts, Home Manager deployment, and application-native dotfiles.

## Architecture

- `dotfiles/` contains native Bash, TOML, JSON, inputrc, Lua, and application
  configuration. Edit these repository files rather than their immutable
  Home Manager links under `$HOME`.
- `home/common.nix` deploys portable files; `home/linux.nix` adds Linux-only
  MIME, user-directory, and `lf` configuration. These modules do not depend on
  NixOS and can later be reused by standalone Home Manager or nix-darwin.
- `nixos/profiles/base.nix` provides the small common operating system.
  `nixos/profiles/laptop.nix` composes the normal full workstation, while
  `nixos/profiles/bootstrap.nix` adds only conservative build limits.
- `nixos/features/` contains independently reusable capabilities such as
  COSMIC, development, NVIDIA, virtualization, and network tooling.
- `hardware/` contains physical boot/CPU facts. Turing's AMD/NVIDIA PRIME bus
  IDs live in `hardware/turing.nix`, not in the reusable NVIDIA feature.
- `disko/` owns storage. Turing and Hermes share the GPT + EFI + LUKS + Btrfs
  layout while retaining their original LUKS names and swap sizes.
- `hosts/turing/` is the thin composition layer. Hermes retains hardware and
  Disko knowledge only; it is not exposed as a complete NixOS configuration.

There is no CUDA workload configured. The full Turing configuration preserves
the CUDA binary cache independently from NVIDIA driver support.

## Package policy

Packages remain in `environment.systemPackages` so command-line, development,
and workstation tools are also available through `sudo`. Home Manager starts
with an empty `home.packages`; it deploys the raw configuration files and uses
the same `pkgs` instance as NixOS.

Neovim remains a system package with Nix-managed plugins and runtime tools.
Its actual `init.lua` is a portable raw dotfile. Non-NixOS platforms will need
to provision the same plugins separately; no plugin manager is introduced here.

## Normal rebuild

```bash
just rebuild
# Equivalent:
sudo nixos-rebuild switch --flake .#turing
```

Home Manager activates as part of the NixOS generation; do not run a separate
`home-manager switch` on NixOS.

## Fresh bootstrap installation

The install command destroys and repartitions the selected device. Verify it
with `lsblk` and prefer a `/dev/disk/by-id/...` path.

```bash
just install turing /dev/disk/by-id/<target-device>
```

This installs `.#turing-bootstrap` with low Nix concurrency. After booting the
minimal system, clone or enter this repository and build the normal system:

```bash
just rebuild
```

To remain on or explicitly rebuild the bootstrap generation:

```bash
just rebuild-bootstrap
# Equivalent:
sudo nixos-rebuild switch --flake .#turing-bootstrap
```

## Home Manager ownership

The declared dotfiles use targeted `force = true` ownership. Rebuilding replaces
those exact home-directory targets with immutable Home Manager links, making
this repository their source of truth. GNU Stow is neither installed nor part
of the deployment workflow.

## Compatibility baselines and shell assumptions

`system.stateVersion` remains `25.05`. Home Manager was introduced with
`home.stateVersion = "26.05"`. Neither value should be changed during routine
updates without reviewing the corresponding migration notes.

The imported `.bash_profile` is intentionally unchanged. It creates XDG
directories at login, assumes those variables reach interactive shells, adds
the optional Doom Emacs path, and resolves programs with `command -v`. It still
looks up Alacritty for `TERMINAL` even though Ghostty is installed; on systems
where a named program is unavailable, the exported value may be empty. These
are documented migration follow-ups rather than silent rewrites.

Hermes' old AMD PRIME IDs were inconsistent with its Intel hardware and were
not retained. Verified Intel/NVIDIA PCI bus IDs are required before enabling
the NVIDIA feature on that hardware.
