## Building VM images and virtual disks from NixOS configurations
`nixos-generators` is the software used to build VM images from `flake.nix` and `configuration.nix` files and it is available as a Nix package [here](https://search.nixos.org/packages?channel=unstable&show=nixos-generators&from=0&size=50&sort=relevance&type=packages&query=nixos-generators). VM images can be built for many platforms including _VirtualBox_, _Amazon EC2_, _Docker_, _VMWare_, _Azure_, etc. See the `nixos-generators` [documentation](https://github.com/nix-community/nixos-generators) for more details. 

Whilst `nixos-generators` is available for many platforms (from NixPkgs: aarch64-darwin, aarch64-linux, i686-linux, x86_64-darwin, x86_64-linux), the target image type and target architechture impose requirements on the system used to build the image.

E.g. Building on `aarch-darwin` for `x86_64-linux` involves cross-compiling. There are instructions in the `nixos-generators` docs about cross-compiling, and the process is more straightforward if the build system is running NixOS.

If an `aarch-linux` or `x86_64-linux` build system running NixOS is available then building aarch or x86 images is quite straightforward.

### Worked example - building an x86 image for _VirtualBox_ using an `aarch-linux` build system running NixOS
1. Add `boot.binfmt.emulatedSystems = [ "x86_64-linux" ];` to the build system `/etc/nixos/configuration.nix` file and `nixos-rebuild switch` to enable cross compilation from aarch to x86.
2. Run `nix-shell -p nixos-generators` to obtain a shell with `nixos-generators` available. 
3. Run `nixos-generate -f virtualbox --system x86_64-linux` to build an image with the default configuration (found at ). This will take a while.

### Building images with custom Nix configurations (from a `configuration.nix` file)
You'll probably want to build an image with a custom `configuration.nix` file, do that with `nixos-generate -f <image-type> --system <target-system> -c <path to configuration.nix>`.

### Building images from `flake.nix` configurations.
`nix build .#azure --extra-experimental-features nix-command --extra-experimental-features flakes`

