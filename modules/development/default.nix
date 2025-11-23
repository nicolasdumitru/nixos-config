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

  # Needed for Java JDK (even in devshells)
  programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  #   # Add any missing dynamic libraries for unpackaged programs
  #   # here, NOT in environment.systemPackages
  # ];

  environment.systemPackages = with pkgs; [
    alacritty

    neovim
    tree-sitter
    zed-editor
    vscode-fhs

    git
    git-lfs

    conda

    codex

    just
    stow
  ];
}
