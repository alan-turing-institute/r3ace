# flake.nix
{
  description = "A simple NixOS flake that provides a thin wrapper around a traditional configuration.nix file.";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    serving.url = "github:edchapman88/serving/v1.0.2";
    blue.url = "github:edchapman88/blue/v0.1.13";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    # Please replace my-nixos with your hostname
    nixosConfigurations.hilbert = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      # Pass the inputs (including the 'serving' input data source) on to sub-modules.
      specialArgs = { inherit inputs; };

      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        ./configuration.nix
        # Add hardware support specific to device. See list of devices here:
        # https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
        # nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
  };
}
