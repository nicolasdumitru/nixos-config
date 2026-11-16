{ ... }:

{
  # Tailscale, to reach babbage. Sign in once with `sudo tailscale login`.
  # Turing only starts connections, so nothing is opened in the firewall.
  services.tailscale = {
    enable = true;
    # Let nick control Tailscale without sudo, as the tray menu needs.
    extraSetFlags = [ "--operator=nick" ];
  };

  # Manage its rules through nftables directly rather than the iptables
  # compatibility layer.
  systemd.services.tailscaled.serviceConfig.Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];

  # The Tailscale tray icon, started with the desktop session.
  home-manager.users.nick.services.tailscale-systray.enable = true;
}
