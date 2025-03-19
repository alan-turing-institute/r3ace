{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    serving.url = "github:edchapman88/serving/v1.0.2";
    blue.url = "github:edchapman88/blue/v0.1.13";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }@inputs: {
    packages.aarch64-linux = {
      azure = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        modules = [
          {
            virtualisation.diskSize = 5 * 1024;
          }
          ./configuration.nix
        ];
        format = "azure";
        # optional arguments:
        # explicit nixpkgs and lib:
        # pkgs = nixpkgs.legacyPackages.x86_64-linux;
        # lib = nixpkgs.legacyPackages.x86_64-linux.lib;
        # additional arguments to pass to modules:
        specialArgs = { inherit inputs; };
        # specialArgs = { myExtraArg = "foobar"; };
        # you can also define your own custom formats
        # customFormats = { "myFormat" = <myFormatModule>; ... };
        # format = "myFormat";
      };
      iso = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "iso";
        specialArgs = { inherit inputs; };
      };
      vmware = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        modules = [
          {
            virtualisation.diskSize = 5 * 1024;
          }
          ./configuration.nix
        ];
        format = "vmware";
        specialArgs = { inherit inputs; };
      };
    };
  };
}
