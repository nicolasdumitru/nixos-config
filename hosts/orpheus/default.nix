{
  dotfilesPath,
  modules,
  pkgs,
  ...
}:

{
  imports = [
    modules.nixos.features.nixConfig
    modules.nixos.features.neovim
    modules.nixos.features.shell
  ];

  networking.hostName = "orpheus";

  # NixOS-WSL creates the default user with sudo access.
  wsl = {
    enable = true;
    defaultUser = "nick";
  };

  programs.nix-ld.enable = true;

  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    neovim
    git
    direnv
  ];

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath modules;
    };
    users.nick = {
      imports = [
        modules.homeManager.dotfiles.common
        modules.homeManager.dotfiles.linux
        modules.homeManager.neovimConfig
        modules.homeManager.neovimPackages
        modules.homeManager.cliTools
        modules.homeManager.development
      ];
      home.username = "nick";
      home.homeDirectory = "/home/nick";
    };
  };

  # Preserve the compatibility baseline from the initial WSL installation.
  system.stateVersion = "26.05";
}
