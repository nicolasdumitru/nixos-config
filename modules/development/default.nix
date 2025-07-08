{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.development.c-cpp
    # self.nixosModules.development.dotnet
    self.nixosModules.development.rust
    self.nixosModules.development.python
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

    just
    stow

    nixd
    nixfmt-rfc-style
  ];
}
