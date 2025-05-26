{
  pkgs,
  inputs, # for rust-overlay
  ...
}:

{
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
  environment.systemPackages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = [
        "rust-analyzer"
        "rust-src"
        "rust-docs"
      ];
    })
  ];
}
