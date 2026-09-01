# NixOS, Home Manager, and Dotfiles

This repository contains the complete `turing` system configuration, a small
bootstrap configuration, reusable NixOS features, physical hardware facts,
Disko layouts, Home Manager deployment, and application-native dotfiles.

## Architecture

- `dotfiles/` contains native Bash, TOML, JSON, inputrc, Lua, and application
  configuration. Edit these repository files rather than their immutable
  Home Manager links under `$HOME`.
- `modules/home-manager/` contains portable configuration and standalone
  package modules. Common dotfiles work on every Home Manager platform; MIME
  and user-directory files remain isolated in the Linux module.
- `modules/nixos/profiles/base.nix` provides the small common operating system.
  The laptop profile adds only laptop policy, while the Turing host explicitly
  selects desktop, development, GPU, virtualization, and peripheral features.
- `modules/nixos/features/` contains independently reusable NixOS capabilities.
  Desktop environment, audio, applications, and fonts are separate choices.
- `lib/package-sets/` contains plain package-selection functions shared by thin
  NixOS and standalone Home Manager modules; it does not contain module policy.
- `hardware/` contains physical boot/CPU facts. The ROG Zephyrus G16's
  AMD/NVIDIA PRIME bus IDs live in `hardware/rog-zephyrus-g16.nix`, not in the
  reusable NVIDIA feature.
- `disko/` owns storage. The `turing` and `hermes` Disko compositions share the
  GPT + EFI + LUKS + Btrfs layout while retaining their original LUKS names and
  swap sizes.
- `hosts/turing/` is the thin composition layer. The ASUS TUF F15 retains
  hardware and Disko knowledge only; it is not exposed as a complete NixOS
  configuration.

There is no CUDA workload configured. The full Turing configuration preserves
the CUDA binary cache independently from NVIDIA driver support.

## Package policy

On NixOS, packages remain in `environment.systemPackages` so command-line,
development, and workstation tools are available to every user, including
root. Integrated Home Manager deploys configuration files but does not duplicate
these programs in `home.packages`. Standalone Home Manager modules install the
same shared package sets per-user on generic Linux and Darwin.

Neovim is constructed once as a portable Nix package with Nix-managed plugins
and runtime tools. NixOS installs it system-wide; standalone Home Manager installs
the same derivations per-user. Its wrapper leaves XDG startup discovery enabled,
so the native `dotfiles/.config/nvim/init.lua` is loaded normally on both.

## Portable Home Manager composition

The flake exports atomic modules rather than fabricated standalone hosts. A
generic Linux home can compose:

```nix
modules = [
  inputs.config.homeModules.dotfiles-common
  inputs.config.homeModules.dotfiles-linux
  inputs.config.homeModules.neovim-config
  inputs.config.homeModules.neovim-packages
  inputs.config.homeModules.cli-tools
  inputs.config.homeModules.development
];
```

Darwin uses the same composition without `dotfiles-linux`. On NixOS, the system
imports the NixOS package modules and integrated Home Manager imports only the
corresponding configuration modules.

The pinned Nixpkgs 26.11 no longer supports `x86_64-darwin`, so this flake checks
Apple Silicon Darwin. The modules themselves do not encode an architecture;
Intel Darwin consumers need a Nixpkgs branch that still supports that platform.

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

The ASUS TUF F15's old AMD PRIME IDs were inconsistent with its Intel hardware
and were not retained. Verified Intel/NVIDIA PCI bus IDs are required before
enabling the NVIDIA feature on that hardware.
