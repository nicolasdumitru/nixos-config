{ ... }:

{
  # Shared secret store for every desktop session: GNOME Keyring
  # (~/.local/share/keyrings), unlocked by PAM at login. Desktop modules import
  # this so secrets survive switching between sessions.
  services.gnome.gnome-keyring.enable = true;
}
