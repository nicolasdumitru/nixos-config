{
  inputs,
  pkgs,
}:

let
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
    binutils
    vscode
    antigravity-ide
    git
    git-lfs
    gh
    codex
    antigravity-cli
    just
    rustToolchain
  ];

  linux =
    with pkgs;
    lib.optionals stdenv.hostPlatform.isLinux [
      glibc
      conda
    ];
in
pkgs.lib.filter (pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform) (portable ++ linux)
