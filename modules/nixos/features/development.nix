{
  inputs,
  pkgs,
  ...
}:

{
  systemd.coredump.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.nix-ld.enable = true;

  environment.systemPackages = import ../../../lib/package-sets/development.nix {
    inherit inputs pkgs;
  };
}
