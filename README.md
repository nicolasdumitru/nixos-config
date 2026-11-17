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

Every host uses nftables. On the hosts with the base profile it backs the
NixOS firewall; Orpheus enables it without a firewall, as WSL runs none.

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

### Tailscale

Babbage and Turing run Tailscale, each configured in its own host file. Sign
each machine in once with `sudo tailscale login`. Babbage accepts direct
connections and trusts everything arriving over the tailnet, so any device
signed in to it can reach every port on Babbage. Turing only starts
connections and opens nothing.

Babbage also runs Tailscale SSH: from a device in the tailnet, `ssh nick@babbage`
logs in with your Tailscale identity, without SSH keys. The tailnet policy
decides who may log in; its default lets you reach your own devices, asking
you to confirm in the browser from time to time.

### Seafile

Babbage's main job is Seafile, the file sync server for Turing, the iPhone,
and Windows (`hosts/babbage/seafile.nix`). Seafile's server is no longer
packaged in nixpkgs, so it runs upstream's official container images (Seafile,
MariaDB, Redis) under Podman, pinned to exact versions. It is reachable only
over the tailnet, with HTTPS from `tailscale serve`:

<https://babbage.tailce49d3.ts.net>

Everything lives in `/var/lib/seafile`: the files and Seafile's configuration
in `data/`, the database in `mysql/`, and the passwords and keys, generated on
the first start, in `secrets/` (root only). The containers keep no state of
their own, so switching `virtualisation.oci-containers.backend` to `docker`
recreates them on the same data.

The tailnet must allow HTTPS certificates once: in the Tailscale admin console,
DNS page, enable HTTPS Certificates. After the first start, log in on the web
page as `admin@babbage.local` with the generated password, and create your own
account for syncing:

```bash
sudo grep INIT_SEAFILE_ADMIN_PASSWORD /var/lib/seafile/secrets/seafile.env
```

The clients connect to the same address. Logs:

```bash
journalctl -u podman-seafile -u podman-seafile-mysql -u seafile-tailscale-serve
```

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

## Discrete GPU monitor on Turing

`modules.gpu-monitor` logs every time the NVIDIA GPU powers up, with the
process that asked for it, every other process that requests it while it is
on, and a summary of who requested it last when it powers down again:

```bash
journalctl -u gpu-monitor
```

When the GPU comes on while on battery, or is still on when the charger is
unplugged, it also sends a desktop notification, at most once every five
minutes. The monitor never queries the GPU, so it does not wake it. Tools such
as `nvidia-smi` do, and show up in the log as the cause.

## Fresh bootstrap installation

The install command destroys and repartitions the selected device. Verify it
with `lsblk` and prefer a `/dev/disk/by-id/...` path.

Boot the installer ISO built from this repository (below), clone the
repository, and run:

```bash
just install turing /dev/disk/by-id/<target-device>
```

The official NixOS ISOs ship with flakes disabled. From one of those, open a
shell with the tools first, then use the compatibility recipe, which enables
flakes for the installation only:

```bash
nix-shell -p git just
just install-compat turing /dev/disk/by-id/<target-device>
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

### Installer ISO

`hosts/lovelace/` holds two installers, both with flakes enabled, Neovim, Git,
`just`, and the same zsh, dotfiles, and command-line tools as the other hosts
for their `nixos` user:

- `graphical` logs straight into the COSMIC desktop, set up as on Turing, with
  the same applications, plus GParted and Firefox from the NixOS installer.
- `minimal` is the console-only NixOS installer.

Build them with `just iso [graphical|minimal|both]` (graphical by default);
each image lands in `result-<variant>/iso/`. `just burn <device> [graphical|minimal|<file>]`
writes one of those images, or any other image file, to a USB stick. It does
not build anything: without the image it asks you to run `just iso` first. It
refuses internal disks and mounted sticks, asks for confirmation, and verifies
the copy afterwards. Any image writer works too.

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
