{ pkgs, ... }:

{
  home.packages = import ../../lib/package-sets/cli-tools.nix { inherit pkgs; };
}
