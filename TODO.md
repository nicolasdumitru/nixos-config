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
