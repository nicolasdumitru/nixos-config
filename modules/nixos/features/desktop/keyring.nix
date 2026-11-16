{ config, lib, ... }:

let
  desktop = config.modules.desktop;
in
{
  # Shared secret store for every desktop session: GNOME Keyring
  # (~/.local/share/keyrings), unlocked by PAM at login. Every desktop uses it,
  # so secrets survive switching between sessions.
  config = lib.mkIf (desktop.cosmic.enable || desktop.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
  };
}
