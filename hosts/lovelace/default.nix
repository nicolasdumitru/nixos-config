# The installer ISO: the minimal NixOS installer with flakes enabled and the
# same command-line environment as the other hosts. It is not installed
# anywhere itself; it installs the other hosts with `just install`.
{
  dotfilesPath,
  lib,
  modules,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    modules.nixos
  ];

  networking.hostName = "lovelace";

  # The installer normally writes its own configuration to /etc/nixos. That
  # reads the `modules` module argument, which this flake's `modules`
  # argument replaces, and the copy would be of no use anyway: hosts are
  # installed from this flake.
  installer.cloneConfig = false;
  image.baseName = lib.mkForce "lovelace-${pkgs.stdenv.hostPlatform.system}";

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
