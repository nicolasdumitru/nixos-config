{ inputs }:

{
  homeManager = import ./home-manager { inherit inputs; };
  nixos = import ./nixos;
  packageSets = import ./package-sets;
}
