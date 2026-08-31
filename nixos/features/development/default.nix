{ pkgs, ... }:

{
  imports = [ ./rust.nix ];

  systemd.coredump.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    gcc
    glibc
    binutils
    vscode
    antigravity-ide
    git
    git-lfs
    gh
    conda
    codex
    antigravity-cli
    just
  ];
}
