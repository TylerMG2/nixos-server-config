{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable flakes
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # Bootloader
  boot.loader.grub = {
    enable = true;
    device = "/dev/sdb";
    useOSProber = true;
  };

  networking.hostName = "nixos-server";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account
  users.mutableUsers = true;
  users.users.tylerg = {
    isNormalUser = true;
    description = "Tyler Gwin";
    extraGroups = ["networkmanager" "wheel" "oci"];
    hashedPasswordFile = "/etc/nixos/tylerg.passwd";
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    podman
    home-manager
    htop
    wireguard-tools
  ];

  # Enable the OpenSSH daemon. TODO: Remove root login and password login
  services.openssh = {
    enable = true;
  };

  # Vscode server
  services.vscode-server.enable = true;

  # FIX
  networking.firewall = {
    enable = true;
    # TODO: Setup nginx proxy
    allowedTCPPorts = [
      22 # SSH
      8096 # Jellyfin http
      8920 # Jellyfin HTTPS
      9443 # Portainer HTTPS
      9000 # Portainer HTTP
      25565 # Minecraft game port
    ];
    allowedUDPPorts = [51810]; # Wireguard
  };

  #TODO: Move out
  # Podman + Portainer Setup
  users.users.podman = {
    isSystemUser = false;
    isNormalUser = true;
    description = "Podman user";
    home = "/home/podman";
    createHome = true;
    group = "podman";
    uid = 1200;
    linger = true;
    shell = pkgs.bash; #TODO: Remove later
  };

  users.groups.podman = {
    name = "podman";
    gid = 1201;
  };

  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Create dirs for portainer
  # TODO: Maybe we can move this home configuration somehow
  systemd.tmpfiles.rules = [
    ''d /home/podman/portainer 0750 podman podman -''
    ''d /home/podman/minecraft 0750 podman podman -''

    ''d /home/podman/jellyfin 0750 podman podman -''
    ''d /home/podman/jellyfin/config 0750 podman podman -''
    ''d /home/podman/jellyfin/cache 0750 podman podman -''
    ''d /home/podman/jellyfin/media 0750 podman podman -''
  ];

  # Wireguard VPN for connecting to services
  networking.wireguard.interfaces.wg0 = {
    ips = ["10.100.0.1/24"];
    listenPort = 51810;
    privateKeyFile = "/etc/nixos/wireguard/privatekey";

    # The peer (client)
    peers = [
      # Phone
      {
        publicKey = "0YAk4+GXspOXWIYS7Bi9EZU1BydKY3NA4kGw5PjUnyk=";
        allowedIPs = ["10.100.0.2/32"];
      }
      # Desktop
      {
        publicKey = "+4Ghklg+ZBna+yym0vbh0b4yC2w9XTnhdFLdIL9bVSo=";
        allowedIPs = ["10.100.0.3/32"];
      }
    ];
  };

  system.stateVersion = "25.05";
}
