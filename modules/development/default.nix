{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.development.c-cpp
    self.nixosModules.development.python
  ];

  environment.systemPackages = with pkgs; [
    alacritty

    neovim
    emacs
    tree-sitter

    git

    just
    stow

    rustup

    nil
    nixfmt-rfc-style

    lua-language-server

    shellcheck
    nodePackages.bash-language-server
    nodejs
  ];
}
