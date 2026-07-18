{
  self,
  pkgs,
  ...
}:

{
  imports = [
    self.nixosModules.neovim
    self.nixosModules.rust
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

  # Neovim
  modules.neovim.enable = true;

  environment.systemPackages = with pkgs; [
    ghostty

    zed-editor
    vscode
    antigravity

    git
    git-lfs
    gh # GitHub CLI

    conda

    gemini-cli

    just
    stow
  ];
}
