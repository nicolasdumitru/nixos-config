# Shared by both installer ISOs: flakes enabled and the same command-line
# environment as the other hosts. The installers are not installed anywhere
# themselves; they install the other hosts with `just install`.
{
  dotfilesPath,
  modules,
  pkgs,
  ...
}:

{
  imports = [ modules.nixos ];

  networking.hostName = "lovelace";

  # The installer normally writes its own configuration to /etc/nixos. That
  # reads the `modules` module argument, which this flake's `modules`
  # argument replaces, and the copy would be of no use anyway: hosts are
  # installed from this flake.
  installer.cloneConfig = false;

  modules = {
    nix-config.enable = true;
    editor.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    just
    ripgrep
    fd
    bash-completion
  ];

  # The installer's own user, logged in automatically, gets the usual shell.
  programs.zsh.enable = true;
  users.users.nixos.shell = pkgs.zsh;

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit dotfilesPath;
    };
    users.nixos = {
      imports = [ modules.homeManager ];

      modules = {
        dotfiles.enable = true;
        neovim.enable = true;
        cli-tools.enable = true;
        zsh.enable = true;
      };

      home.username = "nixos";
      home.homeDirectory = "/home/nixos";

      # Do not change this during routine upgrades.
      home.stateVersion = "26.11";
    };
  };
}
