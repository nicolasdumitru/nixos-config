# TODO

## Decide how Neovim is installed system-wide

Every system needs an editor, so the base profile enables `modules.editor`
(`modules/nixos/features/editor.nix`): a plain Neovim without plugins, set as
`EDITOR` for all users, including root. The users' Home Manager configuration
(`modules.neovim`) also installs Neovim, built with plugins and runtime tools.

On the full systems this means two different Neovim builds are installed.
Which one runs is decided by `PATH`: NixOS puts per-user profiles, where Home
Manager installs packages, before the system profile (`environment.profiles`,
with `/run/current-system/sw` pinned last by nixpkgs). That ordering is
deliberate and stable, and the dotfiles only append to `PATH`. Still, which
Neovim runs depends on context: sudo, systemd services, or programs started
from the desktop can see a different `PATH` and get the build without plugins.

Options:

1. **One Neovim build everywhere.** Build the configured Neovim once as a
   package. Home Manager installs it for its users and the system installs the
   same build for everyone else. With a single build, `PATH` order no longer
   matters. The configuration (`init.lua`) stays per-user, so other users and
   root get the plugins but not the configuration.
2. **Plain Neovim only in the bootstrap profile.** The full systems then have
   only the Home Manager Neovim, so nothing competes. Root and other users on
   the full systems fall back to nano.
3. **Keep the current setup.** It works; the only cost is the
   context-dependent choice of build described above.

## Carry the installer's network settings over in `just install`

Installing should not require connecting to the network again on the new
system. By default, `just install` should copy the installer's NetworkManager
connections (`/etc/NetworkManager/system-connections/`) into the installed
system, with a parameter to turn it off (for example `network=no`). Both
installer ISOs and the official NixOS ISOs use NetworkManager.

- disko-install already supports this: `--extra-files SOURCE DEST` copies a
  file or directory into the new system before installing it, keeping
  ownership and permissions (`cp -a`), so the connection files stay root-only.
  The target disk is encrypted, so the copied Wi-Fi passwords are as protected
  as anything else on it.
- Wired connections work without any of this; it matters for Wi-Fi.
- To check first: a network joined from a desktop network applet may be saved
  with its password in the user's keyring rather than in the connection file.
  Copying the file then carries the network over without its password. Test
  how COSMIC's applet on the graphical installer saves it; if it uses the
  keyring, have the recipe warn about copied networks without a saved
  password. Networks joined with `nmtui` or `nmcli` keep the password in the
  file.

## Decide how to handle turing's macro keys

On turing (ROG Zephyrus G16 GA605WV), the keyboard firmware sends Windows
shortcuts instead of single keycodes for some keys. Seen with `evtest` on the
internal keyboard ("Asus Keyboard", `0b05:19b6`):

- Print and Fn+F6 send LeftMeta + **RightShift** + S (Win+Shift+S).
- Fn+F9 sends LeftMeta + P (Win+P), with Meta held as long as the key is.
- Fn+F10 (touchpad toggle) probably sends Ctrl+Meta+F24 as on similar models;
  not checked.

These are ordinary key presses, indistinguishable from typing the combination,
so neither the kernel, hwdb nor COSMIC can turn them back into `KEY_SYSRQ` and
the like. COSMIC can only bind shortcuts to the combinations. The COSMIC
shortcuts already bind Super+Shift+S to the screenshot tool, so Print works
there; Super+P is bound to KeePassXC, so Fn+F9 opens KeePassXC.

As of November 2026, COSMIC has no plans to remap keys: the requests
([cosmic-epoch#3232](https://github.com/pop-os/cosmic-epoch/issues/3232) for
the Copilot key, which is the same kind of macro, and
[cosmic-settings#383](https://github.com/pop-os/cosmic-settings/issues/383))
have no maintainer response, and the Epoch 2/3 roadmap does not mention it.

Options:

1. **Keep using COSMIC shortcuts.** Nothing to install. Applications never see
   a real Print key, and Fn+F9 can only do whatever Super+P does.
2. **kanata** (Rust), in the `asus-laptop` module. Limit it to the internal
   keyboard with `devices` (its `/dev/input/by-id/...` path) and use
   `defoverrides` to map LeftMeta+RightShift+S to `sysrq`, and Super+P to
   whatever Fn+F9 should be (which takes Super+P away from KeePassXC on the
   laptop keyboard). Since it uses RightShift, the screenshot macro is rarely
   typed by hand, so remapping it costs little. The NixOS `services.kanata`
   module does not run it as root: `DynamicUser`, only the `input` and
   `uinput` groups, no capabilities, `PrivateNetwork`, system-call filter.
   - Trust: like any remapper, it reads every key on that keyboard and can
     type through `/dev/uinput`, so a malicious release could type commands
     into a terminal and get around the sandbox. That is no more than the
     compositor or any program running as the user can already do; updates
     come through nixpkgs review and the flake lock.

## Decide how babbage's encrypted disk is unlocked at boot

Babbage's disk is encrypted, and `modules.remote-unlock` is off, so after
every reboot babbage waits for the passphrase on its own console. Until then
Tailscale is not running and babbage cannot be reached, which defeats
powering it on remotely.

Options:

1. **Unlock over SSH during boot** (`modules.remote-unlock`, already written).
   An SSH server in the initrd takes a DHCP address on the wired network and
   asks for the passphrase on port 2222. Encryption stays as strong as now.
   Needs, before it can be enabled:
   - At least one public key in `modules.ssh-server.authorizedKeys`. Tailscale
     SSH cannot help here: Tailscale is not running yet at that point of the
     boot.
   - The wired network card's driver in `hardware/tuf-f15.nix` (`r8169` is
     assumed); check with `lspci -k` on babbage.
   - A boot-time SSH host key generated on babbage (see the README).
   - From outside the home network, a way to reach babbage's LAN address
     during boot, such as another always-on device on the tailnet to hop
     through.
2. **Unlock automatically with the TPM** (`systemd-cryptenroll`). Babbage boots
   unattended and joins the tailnet by itself, so remote power-on just works.
   It protects a disk taken out of the machine, but someone who steals the
   whole laptop gets a booted system, guarded only by the login password.
3. **Keep unlocking at the console.** Nothing to set up; babbage is only
   reachable after someone types the passphrase on it.

## Back up Seafile's database and configuration from babbage

Seafile on babbage keeps the synced files in its own block store, and turing's
Kopia backups already cover them, as long as every Seafile library is also
synced to turing (or another machine backed up with Kopia). Libraries used
only from the iPhone or Windows would otherwise exist only on babbage.

What exists only on babbage is Seafile's bookkeeping: accounts, the list of
libraries, sharing, and Seafile's own file history and trash (in MariaDB), plus
its configuration in `/var/lib/seafile/data/seafile/conf`. Losing it means
recreating the accounts and libraries by hand and re-uploading from turing.

Plan: a nightly systemd service on babbage that dumps the three databases
(`ccnet_db`, `seafile_db`, `seahub_db`) with `mariadb-dump --single-transaction`
inside the `seafile-mysql` container, then snapshots the dump and the
configuration with Kopia into the same repository as the other machines. It is
a few megabytes. Copying `/var/lib/seafile/mysql` directly is not a consistent
backup while MariaDB runs.

Backing up the block store itself (`/var/lib/seafile/data/seafile/seafile-data`)
would mostly duplicate turing's backups without deduplicating against them:
Seafile splits files into blocks at its own boundaries, so Kopia's chunks of
those blocks do not match its chunks of the original files.
