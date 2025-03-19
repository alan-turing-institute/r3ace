# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

# Use 'inputs' which is a custom argument passing the inputs to the parent flake.nix file into this file (which will be parsed as a sub-module to flake.nix).
{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Enable the Flakes feature and the accompanying nix command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "kleene"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.  
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  #    useXkbConfig = true; # use xkbOptions in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nixos = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
  #     firefox
       tree
    ];
  };

  users.users.blue = {
     isNormalUser = true;
     extraGroups = [ "wheel" "dialout" ];
     packages = with pkgs; [
        tree
     ];
     initialPassword = "changeme";
  };

  security.sudo.wheelNeedsPassword = false;

  # Add Certificate Authority certificates to the CA bundle.
  security.pki.certificateFiles = [
    # Custom CA used to sign certs for the PIs in the R3 project (including the webserver on Kleene).
    ./some-cert-auth.crt
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     emacs
     wget
     git
     # Install the 'getting' package from the input data source defined in the parent flake.nix file.
     libev
     inputs.getting.packages."${pkgs.system}".default
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Start up the 'getting' http request program.
  systemd.services.getting = {
    # 20 requests per second (RPS)
    script = "getting -p /dev/ttyUSB0 -l /home/blue/got_logs -i 0.05 -h /etc/nixos/hosts.yaml https://serving.local";
    path = with pkgs; [
      inputs.getting.packages."${pkgs.system}".default
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # Increase the max number of unix file descriptors to 20,000. Required by the `getting` request program for high throughput.
    serviceConfig = {
      LimitNOFILE = "20000";
      # Allows writing of a log file to /home/blue .
      User = "blue";
      # Required for writing to serial ports.
      Group = "dialout";
      # Always auto-restart the if the service fails.
      Restart = lib.mkForce "always";
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # To disconnect the machine from your Wifi network, comment out this block. Note that an internet connection (wifi or wired) *will* be required when running `nixos-rebuild switch` to compile changes to the NixOS configuration and switch to that new configuration.
  networking.wireless.networks = {
    "MY WIFI" = {
      psk = "NETWORK PASSWORD";
    };
  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      agent = {
        interval = "1s";
      };
      inputs = {
        cpu = {
	  percpu = false;
	  totalcpu = true;
	  fieldpass = [ "usage_user" "usage_nice" "usage_system" "usage_iowait" "usage_idle" ];
	};
	disk = {
	  ## Ignore mount points by filesystem type.
  	  ignore_fs = ["tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs"];
	  fieldpass = [ "used_percent" ];
	};
	mem = {
	  fieldpass = [ "used_percent" "buffered" "cached" "swap_cached" "swap_free" "vmalloc_used" ];
	};
      };
      outputs = {
        file = {
          files = ["/var/log/telegraf/telegraf.json"];
	  ## Data format to output. Each data format has its own unique set of configuration options, read more about them here:
  	  ## https://github.com/influxdata/telegraf/blob/master/docs/DATA_FORMATS_OUTPUT.md
	  data_format = "json";
	  rotation_interval = "24h";
	};
      };
    };
  };

  # Ensure a directory exists with the correct permissions for telegraf to write to.
  systemd.tmpfiles.rules = [ "d /var/log/telegraf 0775 root telegraf" ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}

