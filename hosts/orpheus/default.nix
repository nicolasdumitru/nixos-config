{
  dotfilesPath,
  modules,
  pkgs,
  ...
}:

{
  imports = [ modules.nixos ];

  modules = {
    desktop.fonts.enable = true;
    editor.enable = true;
    nix-config.enable = true;
    shell.enable = true;
  };

  networking.hostName = "orpheus";

  # WSL runs no firewall of its own (NixOS-WSL disables the iptables one), so
  # nftables is enabled without a ruleset to keep that unchanged.
  networking.nftables.enable = true;
  networking.firewall.enable = false;

  # NixOS-WSL creates the default user with sudo access.
  wsl = {
    enable = true;
    defaultUser = "nick";
  };

  programs.nix-ld.enable = true;

  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    direnv
  ];

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath;
    };
    users.nick = {
      imports = [ modules.homeManager ];

      modules = {
        dotfiles.enable = true;
        neovim.enable = true;
        cli-tools.enable = true;
        development.enable = true;
        zsh.enable = true;
      };

      home.username = "nick";
      home.homeDirectory = "/home/nick";

      # Home Manager compatibility baseline from the initial migration. Do not
      # change it during routine upgrades.
      home.stateVersion = "26.05";
    };
  };

  # Preserve the compatibility baseline from the initial WSL installation.
  system.stateVersion = "26.05";
}
