{
  pkgs,
  ...
}:

{
  system.extraDependencies = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
    rust-analyzer
  ];
}
