{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.development.c-cpp
    self.nixosModules.development.python
    self.nixosModules.development.dotnet
  ];

  # Use systemd-coredump for core dumps
  systemd.coredump.enable = true;

  environment.systemPackages = with pkgs; [
    alacritty

    neovim
    tree-sitter
    zed-editor

    git

    just
    stow

    rustup

    nixd
    nixfmt-rfc-style

    lua-language-server

    shellcheck
    nodePackages.bash-language-server
    nodejs
  ];
}
