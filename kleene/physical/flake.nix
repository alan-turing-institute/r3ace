# flake.nix
{
  description = "A simple NixOS flake that provides a thin wrapper around a traditional configuration.nix file.";

  inputs = {
    # NixOS official package source, using the nixos-24.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    getting.url = "github:edchapman88/getting/v0.4.3";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Please replace my-nixos with your hostname
    nixosConfigurations.kleene = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      # Pass the inputs on to sub-modules.
      specialArgs = { inherit inputs; };
      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        ./configuration.nix
      ];
    };
  };
}

