# NixOS, Home Manager, and Dotfiles

This repository contains the complete `turing`, `babbage`, and WSL `orpheus` system configurations, small
bootstrap configurations, reusable NixOS features, physical hardware facts,
Disko layouts, Home Manager deployment, and application-native dotfiles.

## Architecture

- `dotfiles/` contains native Bash, TOML, JSON, inputrc, Lua, and application
  configuration. Edit these repository files rather than their immutable
  Home Manager links under `$HOME`.
- `modules/home-manager/` is one Home Manager module that declares options
  under `modules.*` for the portable configuration and packages, used by both
  integrated and standalone Home Manager. Nothing applies until a home enables
  it. Common dotfiles work on every Home Manager platform; MIME and
  user-directory files apply only on Linux.
- `modules/nixos/` is one NixOS module that declares options under `modules.*`.
  Hosts import it once and enable what they want; every feature is off by
  default. `modules.profiles.base` provides the small common operating system.
  The laptop profile adds only laptop policy, while the Turing host explicitly
  enables desktop, development, GPU, virtualization, and peripheral features.
- `modules/nixos/features/` contains one file per NixOS capability. Desktop
  environments, audio, applications, and fonts are separate options. Any
  desktop turns on the shared GNOME Keyring, and `modules.desktop.greeter`
  selects the login screen.
- `modules/default.nix`, `hardware/`, `disko/`, and `hosts/` expose their
  entries through `default.nix` (or a local module-set file where
  `default.nix` is itself a NixOS module). Compositions use entries such as
  `modules.nixos`, `hardware.rog-zephyrus-g16`, and `disko.rog-zephyrus-g16`
  without parent-directory paths.
- `hardware/` contains physical boot/CPU facts. The ROG Zephyrus G16's
  AMD/NVIDIA PRIME bus IDs live in `hardware/rog-zephyrus-g16.nix`, not in the
  reusable NVIDIA feature.
- `disko/` owns storage. The ROG Zephyrus G16 and ASUS TUF F15 compositions
  share the GPT + EFI + LUKS + Btrfs layout while retaining their original LUKS
  names and swap sizes.
- `hosts/` holds the thin composition layers: `turing` on the ROG Zephyrus G16,
  `babbage` on the ASUS TUF F15, and `orpheus` on WSL.

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

Hosts and the portable Home Manager check import the single
`modules.homeManager` module and enable its options:

```nix
imports = [ modules.homeManager ];

modules = {
  dotfiles.enable = true;
  neovim.enable = true;
  cli-tools.enable = true;
  development.enable = true;
  zsh.enable = true;
};
```

The Linux-only dotfiles apply automatically on Linux. Turing and Orpheus use
this module for their integrated Home Manager configurations. The flake
exposes system build targets and checks, but no public module exports.

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

## Orpheus (WSL)

`hosts/orpheus/` builds an x86_64 NixOS-WSL host with `nick` as the default
user and the same Home Manager modules as Turing. The WSL module is pinned
in the flake; no `<nixos-wsl/modules>` channel import is needed.

From the repository inside the existing NixOS-WSL installation, apply it with:

```bash
sudo nixos-rebuild switch --flake path:.#orpheus
```

After the first switch, terminate and reopen the distribution from Windows
to start a session as `nick`. Existing files under `/home/nixos` are not moved
to `/home/nick` automatically. Subsequent rebuilds can use `just rebuild`.

## Babbage (ASUS TUF F15 server)

`hosts/babbage/` is a headless development server: the server profile (base
system, key-only SSH, lid ignored), system development support, and the same
Home Manager modules as Turing. It has no desktop.

Install it like Turing, through its bootstrap configuration, then build the
full system:

```bash
just install babbage /dev/disk/by-id/<target-device>
just rebuild
```

No SSH keys are stored in this repository yet. Until
`modules.ssh-server.authorizedKeys` is set, the SSH server accepts only keys
placed in `~/.ssh/authorized_keys` on the machine itself; passwords are never
accepted.

### Remote power-on

Wake-on-LAN is armed on the wired network card; it must also be enabled in the
firmware setup. Another device on the same network sends the magic packet to
the card's MAC address, for example with `wol <mac-address>`.

### Remote unlock (not enabled yet)

The disk is encrypted, so for now the passphrase is typed on the machine's own
console at boot. `modules.remote-unlock` also accepts it over SSH, and is off
until two things are done:

- Add at least one public key to `modules.ssh-server.authorizedKeys`.
- Confirm the wired network driver in `hardware/tuf-f15.nix` (`r8169` is
  assumed) with `lspci -k` on the machine.

Then generate the boot-time SSH host key on the machine, set
`modules.remote-unlock.enable = true`, and rebuild:

```bash
sudo mkdir -p /etc/secrets/initrd
sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
just rebuild
```

During boot the machine then takes a DHCP address on the wired network and
waits for the passphrase on its console or over SSH on port 2222:

```bash
ssh -p 2222 root@<address>
```

That session is the passphrase prompt; boot continues once the disk unlocks.

### Laptop mode

The `laptop` specialisation turns the same installation into a normal laptop
with the COSMIC desktop and the laptop profile. Choose it in the boot menu, or
switch without rebooting:

```bash
sudo /run/current-system/specialisation/laptop/bin/switch-to-configuration test
```

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

`system.stateVersion` remains `25.05` on Turing and `26.05` on Orpheus. Home Manager was introduced with
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
