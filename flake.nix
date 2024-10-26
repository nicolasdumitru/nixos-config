{
  description = "Nick's NixOS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Lix
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lix-module,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # Personal laptop
        hermes = lib.nixosSystem {
          modules = [
            ./hosts/hermes
            lix-module.nixosModules.default
          ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
      };
    };
}
