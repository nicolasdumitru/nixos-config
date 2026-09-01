{
  modules,
  pkgs,
  ...
}:

let
  userName = "nick";
in
{
  imports = [ modules.nixos.features.nixConfig ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.timeout = 0;
    initrd.systemd.enable = true;
    initrd.verbose = false;
    kernelPackages = pkgs.linuxPackages;
  };

  networking.networkmanager = {
    enable = true;
    # Required for WPA/WPA2 Enterprise for now.
    wifi.backend = "wpa_supplicant";
  };
  networking.firewall = {
    enable = true;
    package = pkgs.iptables;
  };

  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    mutableUsers = true;
    enforceIdUniqueness = true;
    defaultUserShell = pkgs.bashInteractive;
    users.${userName} = {
      name = userName;
      isNormalUser = true;
      home = "/home/${userName}";
      createHome = true;
      useDefaultShell = false;
      shell = pkgs.bashInteractive;
      group = userName;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];

      # Change this immediately after a fresh installation.
      initialPassword = userName;
    };
    groups.${userName} = {
      name = userName;
      members = [ userName ];
    };
  };

  security.sudo.enable = true;
  nix.gc.automatic = false;

  environment.systemPackages = with pkgs; [
    bashInteractive
    coreutils
    util-linux
    htop
    procps
    inetutils
    wget
    curl
    openssh
    git
    just
  ];
}
