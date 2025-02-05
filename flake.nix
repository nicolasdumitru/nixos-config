{
  description = "Nick's NixOS";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Lix
    # Note that this assumes you have a flake-input called nixpkgs,
    # which is often the case. If you've named it something else,
    # you'll need to change the `nixpkgs` below.
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-2.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.follows = "nixos-cosmic/nixpkgs";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";

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
