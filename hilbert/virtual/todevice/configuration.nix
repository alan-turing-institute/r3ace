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

# Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
     font = "Lat2-Terminus16";
     keyMap = "uk";
  #   useXkbConfig = true; # use xkbOptions in tty.
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
     extraGroups = [ "wheel" ];
     packages = with pkgs; [
	tree
     ];
     initialPassword = "changeme";
  };

  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     emacs
     wget
     tailscale
     git
     nginx
     pmacct
     # Install the 'serving' package from the input data source defined in the parent flake.nix file.
     inputs.serving.packages."${pkgs.system}".serving
     inputs.blue.packages."${pkgs.system}".blue
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable
  
  # Start the 'blue' cyber defence program.
  systemd.services.blue = {
    wantedBy = [ "multi-user.target" ];
    script = "blue -l /home/blue/blue_logs -t 10.0 -e 300 -f 0.8 -i 0.05 -g 172.0.0.2 -r 172.0.0.4 -a 172.0.1.3:8081 -s 5.0";
    path = with pkgs; [
      nftables
      inputs.blue.packages."${pkgs.system}".blue
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      # Always auto-restart the if the service fails.
      Restart = lib.mkForce "always";
    };
  };


  # Enable and configure an Nginx reverse proxy
  services.nginx = {
    enable = true;
    # Enables status page reachable from localhost on http://127.0.0.1/nginx_status.
    statusPage = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."serving.local" = {
      forceSSL = true;
      sslCertificate = "/etc/nixos/serving.crt";
      sslCertificateKey = "/etc/nixos/serving.key";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };
    };

  };
  
  # Start up the 'serving' server.
  systemd.services.serving = {
    script = "serving";
    path = with pkgs; [
      inputs.serving.packages."${pkgs.system}".serving
    ];
    wantedBy = [ "multi-user.target" ];
  };
    
  systemd.services.pmacct = {
    script = "pmacctd -f /etc/nixos/pmacctd.conf";
    path = with pkgs; [
      pmacct
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # services.openssh.settings.PasswordAuthentication = false;

  networking = {
    hostName = "hilbert";

    interfaces.eth0.ipv4.addresses = [{
      address = "172.0.0.3";
      prefixLength = 24;
    }];

    interfaces.eth1.ipv4.addresses = [{
      address = "172.0.1.3";
      prefixLength = 24;
    }];

    # Disable the default firewall implementation.
    firewall.enable = false;
    # Use the newer nftables implementation that is declaritive. Dynamic changes to the firewall will not persist between nixos rebuilds.
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          # Check out https://wiki.nftables.org/ for better documentation.

          # Create an empty set of blocked ipv4 addresses to be managed at runtime.
          set blocked { 
            type ipv4_addr
          }

          chain input {
            type filter hook input priority 0;

            # accept any localhost traffic
            iifname lo accept

            # accept traffic originated from us
            ct state {established, related} accept

            # allow "ping"
            ip6 nexthdr icmpv6 icmpv6 type echo-request accept
            ip protocol icmp icmp type echo-request accept

            # drop traffic to port 443 from any addresses in the set 'blocked'
            ip saddr @blocked tcp dport 443 drop

            # accept SSH connections and allow HTTPS on TCP/443
            tcp dport { 22, 443 } accept

            # accept UDP traffic on port 8081
            udp dport { 8081 } accept

            # count and drop any other traffic
            counter drop
          }
        }'';
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
	nginx = {
	  urls = ["http://localhost/nginx_status"];
	};
	netflow = {
	  service_address = "udp://:2055";
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
  system.stateVersion = "23.11"; # Did you read the comment?

}

