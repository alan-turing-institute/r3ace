# Notes for developing with NixOS
## Contents
1. [**Using Flakes**](#using-flakes): General tips about using 'Flakes' with NixOS
2. [**Installing software using Flakes**](#installing-software-using-flakes): Installing your own software onto a NixOS machine (using flakes) - in other words, turning your own software into a Nix Package

## Using Flakes
Flakes is still an experimental feature in Nix. It's enabled in `/etc/nixos/configuration.nix` with:

```
# Enable the Flakes feature and the accompanying new nix command-line tool
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Note that `git` must be available too, e.g. with:
```
environment.systemPackages = with pkgs; [
    git
    ...
];
```

With Flakes enabled, **`nixos-rebuild switch` will prioriotise a `/etc/nixos/flake.nix` file over a `/etc/nixos/configuration.nix` file**.

We can write a **minimal** `flake.nix` file to provide a thin wrapper around our existing `configuration.nix` file, as follows:

```
{
  description = "A simple NixOS flake that provides a thin wrapper around a traditional configuration.nix file.";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Please replace my-nixos with your hostname
    nixosConfigurations.hilbert = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        ./configuration.nix
      ];
    };
  };
}
```

## Installing software using Flakes
The source code for a software 'package' (e.g. an NPM package, an Opam package, a Rust crate) can be made installable as a NixOS package with the addition of a `flake.nix` file at the root of the source code directory. The `flake.nix` file will describe a recipe that creates the NixOS package, and this will be different for NPM packages and Opam packages, etc.

This approach is described in the [_NixOS and Flakes Book_](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-flake-and-module-system#install-system-packages-from-other-flakes), with the helpful example of the [_helix-editor_](https://github.com/helix-editor/helix) package (available on GitHub).

A NixOS package can built by calling `nix build .` in a NixOS installable repo. If successful this creates a binary (runnable on NixOS) in a `./result` directory.

To install the package globally when NixOS boots (in the same way `git`, `nvim` and other software specified in the `environment.systemPackages` section of a `configuration.nix` file isinstalled), the pattern described in the [_NixOS and Flakes Book_](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-flake-and-module-system#install-system-packages-from-other-flakes) is used.

### Debugging a 'buildable', but not 'installable' package
This problem presents it's self at `nixos-rebuild switch` time with errors like:
```
error: attribute '<probably the name of your package>' missing
```
This is a problem not with the package on GitHub, but with the inclusion of the package binary in the `environment.systemPackages` section of the `configuration.nix` file. The specification of the binary will look something like:
```
environment.systemPackages = with pkgs; [
  ...
  inputs.<my_package>.packages."${pkgs.system}".<my_package>
];
```
This path is likely incorrect, and can be debugged with `nix repl`:
1. Change into the directory where your `configuration.nix` file is (your main `flake.nix` file will also be there with is the entry point for the `nixos-rebuild` as described above).
2. Run `nix repl`.
3. Enter `:ls .` which loads the `flake.nix` into the repl.
4. Hit `<tab>` to see completions (where you should see `inputs`).
5. Continue to use autocompletion on `inputs.` etc. to identify the correct path.

### Example of NixOS installable packages for templates
- NPM (Node) package example: [`serving`](https://github.com/edchapman88/serving)
- Dune (OCaml) package example: [`getting`](https://github.com/edchapman88/getting)
- Dune (OCaml) project with multiple packages: [`blue`](https://github.com/edchapman88/blue)

