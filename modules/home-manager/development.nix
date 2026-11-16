{ inputs }:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.development;

  rustBin = inputs.rust-overlay.lib.mkRustBin { } pkgs;
  rustToolchain = rustBin.stable.latest.default.override {
    extensions = [
      "rust-analyzer"
      "rust-src"
      "rust-docs"
    ];
  };

  portable = with pkgs; [
    gcc
    rustToolchain
    binutils
    vscode
    git-lfs
    gh
    codex
    claude-code
    just
    cloc
  ];

  linux =
    with pkgs;
    lib.optionals stdenv.hostPlatform.isLinux [
      glibc
      conda
    ];
in
{
  options.modules.development.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "nicolasdumitru";
          email = "nicolas@ndumitru.com";
        };
        alias = {
          st = "status";
          a = "add";
          l = "log --graph --all --stat";
        };
      };
    };

    home.packages = pkgs.lib.filter (pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform) (
      portable ++ linux
    );
  };
}
