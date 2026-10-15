# NixOS, Home Manager, and Dotfiles

This repository contains the complete `turing` system configuration, a small
bootstrap configuration, reusable NixOS features, physical hardware facts,
Disko layouts, Home Manager deployment, and application-native dotfiles.

## Architecture

- `dotfiles/` contains native Bash, TOML, JSON, inputrc, Lua, and application
  configuration. Edit these repository files rather than their immutable
  Home Manager links under `$HOME`.
- `modules/home-manager/` contains portable configuration and package modules
  used by both integrated and standalone Home Manager. Common dotfiles work on
  every Home Manager platform; MIME and user-directory files remain isolated in
  the Linux module.
- `modules/nixos/profiles/base.nix` provides the small common operating system.
  The laptop profile adds only laptop policy, while the Turing host explicitly
  selects desktop, development, GPU, virtualization, and peripheral features.
- `modules/nixos/features/` contains independently reusable NixOS capabilities.
  Desktop environment, audio, applications, and fonts are separate choices.
- Each module branch exposes its own hierarchy through `default.nix` (or a
  local module-set file where `default.nix` is itself a NixOS module).
  Compositions use entries such as `modules.nixos.features.development`,
  `hardware.rog-zephyrus-g16`, and `disko.rog-zephyrus-g16` without
  parent-directory paths.
- `hardware/` contains physical boot/CPU facts. The ROG Zephyrus G16's
  AMD/NVIDIA PRIME bus IDs live in `hardware/rog-zephyrus-g16.nix`, not in the
  reusable NVIDIA feature.
- `disko/` owns storage. The ROG Zephyrus G16 and ASUS TUF F15 compositions
  share the GPT + EFI + LUKS + Btrfs layout while retaining their original LUKS
  names and swap sizes.
- `hosts/turing/` is the thin composition layer. The ASUS TUF F15 retains
  hardware and Disko knowledge only; it is not exposed as a complete NixOS
  configuration.

There is no CUDA workload configured. The full Turing configuration preserves
the CUDA binary cache independently from NVIDIA driver support.

## Package policy

Home Manager owns the CLI, development, and Neovim package definitions and
installs them through `home.packages`, both for Nick on Turing and for standalone
homes on Linux and Darwin. Existing platform guards keep Linux-only development
packages on Linux. NixOS retains base/bootstrap packages, other system feature
packages, and system integration settings. Migrated packages are available to
the configured user; other users, including root, only receive tools that remain
independently installed system-wide.

The Home Manager CLI module also manages the per-user GnuPG agent, using GNOME
pinentry on Linux and macOS pinentry on Darwin. NixOS does not configure a second
agent for Turing.

Neovim is constructed once as a portable Nix package with Nix-managed plugins
and runtime tools. Integrated and standalone Home Manager install
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

Darwin uses the same composition without `dotfiles-linux`. Turing uses this
same set of Home Manager configuration and package modules alongside its NixOS
system features.

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

## SQL Server on Turing

The full Turing configuration runs Microsoft's SQL Server 2025 Enterprise
Developer container under Docker. This edition is for development and testing.
The configuration accepts Microsoft's EULA and binds only `127.0.0.1:1433`.
SQL Server does not start at boot. Docker itself is socket-activated on demand.

### Daily use

Manage SQL Server as a regular systemd service from any directory:

```bash
sudo systemctl start docker-mssql
sudo systemctl stop docker-mssql
systemctl status docker-mssql
sudo journalctl -u docker-mssql --all -n 50 -f
```

Starting the service also starts Docker; the first startup downloads the image.
Stopping it stops SQL Server; Docker remains available for other containers.
If you also want to stop Docker, after stopping any other containers run
`sudo systemctl stop docker.service docker.socket`. Starting SQL Server again
will start both. SQL Server remains off after a reboot until explicitly started.

An administrator password is generated on first startup in the root-only
`/var/lib/mssql-secrets/environment` file. View it locally with:

```bash
sudo cat /var/lib/mssql-secrets/environment
```

Connect to `127.0.0.1,1433` as `sa` using that password. Existing VS Code
connection profiles still work. Enable trust of the server's self-signed
certificate. The bundled client can
verify the server (it prompts for the password):

```bash
sudo docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q 'SELECT @@VERSION;'
```

Databases live in `/var/lib/mssql` and survive stopping the service, container
recreation, and NixOS rebuilds. Do not delete this directory or the credentials file to reset the
service. Changing the file does not change the password of an existing database;
rotate it within SQL Server and update the file to match. Back up databases
before updating the image. The `2025-latest` tag stays within SQL Server 2025;
to fetch an updated image, run `sudo docker pull mcr.microsoft.com/mssql/server:2025-latest`
and then stop and start SQL Server using the commands above.

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
