# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    getting.url = "github:edchapman88/getting/v0.4.4";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.kleene = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      # Pass the inputs on to sub-modules.
      specialArgs = { inherit inputs; };
      modules = [
        # so the old configuration file still takes effect
        ./configuration.nix
      ];
    };
  };
}

