{
  inputs,
  lib,
  config,
  ...
}:

let
  cfg = config.modules.nix-config;
in
{
  options.modules.nix-config.enable = lib.mkEnableOption "the shared Nix and Nixpkgs settings";

  config = lib.mkIf cfg.enable {
    nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
      lib.filterAttrs (_: lib.isType "flake") inputs
    );

    nix.nixPath = [ "/etc/nix/path" ];
    environment.etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    nixpkgs.config.allowUnfree = true;
    environment.variables.NIXPKGS_ALLOW_UNFREE = 1;
  };
}
