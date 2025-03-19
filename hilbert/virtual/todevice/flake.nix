# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
        ./configuration.nix
      ];
    };
  };
}
