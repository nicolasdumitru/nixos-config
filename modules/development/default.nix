{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.development.rust
  ];

  # Use systemd-coredump for core dumps
  systemd.coredump.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    alacritty

    neovim
    tree-sitter
    zed-editor

    git
    git-lfs

    just
    stow
  ];
}
