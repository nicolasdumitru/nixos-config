{
  description = "Nick's NixOS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Lix
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS COSMIC
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      # A binary cache is built agains the current `nixos-unstable`
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      lix-module,
      nixos-cosmic,
      disko,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;
    in
    {
      nixosModules = import ./modules;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # Personal laptop
        hermes = lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit inputs outputs self;
          };

          modules = [
            ./hosts/hermes

            lix-module.nixosModules.default

            nixos-cosmic.nixosModules.default

            disko.nixosModules.disko

            {
              nix.settings = {
                # Settings can be checked after rebuilds using:
                # `nix config show | rg <setting>`
                # TODO: The default is preserved, but make appending/prepending
                #       to the lists (substituters & trusted keys) explicit
                substituters = [
                  "https://nix-community.cachix.org"
                  "https://cosmic.cachix.org/"
                  # "https://cuda-maintainers.cachix.org/"
                ];
                trusted-public-keys = [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
                  # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                ];
              };
            }
          ];
        };
      };
    };
}
