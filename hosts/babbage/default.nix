{
  lib,
  disko,
  dotfilesPath,
  hardware,
  hosts,
  modules,
  ...
}:

{
  imports = [
    hosts.babbage.common
    hardware.tuf-f15
    disko.tuf-f15
    modules.nixos
  ];

  # A headless development server on the ASUS TUF F15.
  modules = {
    profiles.server.enable = true;

    development.enable = true;
    shell.enable = true;

    # TODO: add public keys to `ssh-server.authorizedKeys`, then enable
    # `remote-unlock`. It needs at least one key and refuses to build without.
    # Until then, SSH accepts only keys placed in ~/.ssh/authorized_keys on the
    # machine itself.
    remote-unlock.enable = false;
    wake-on-lan.enable = true;
  };

  # Emergency use as a normal laptop: pick "laptop" in the boot menu, or run
  # `sudo /run/current-system/specialisation/laptop/bin/switch-to-configuration test`.
  specialisation.laptop.configuration.modules = {
    profiles.server.enable = lib.mkForce false;
    profiles.laptop.enable = true;

    desktop = {
      audio.enable = true;
      applications.enable = true;
      cosmic.enable = true;
      fonts.enable = true;
    };
    disks-filesystems.enable = true;
  };

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

      # Do not change this during routine upgrades.
      home.stateVersion = "26.11";
    };
  };
}
