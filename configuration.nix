{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

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
  users.users.tylerg = {
    isNormalUser = true;
    description = "Tyler Gwin";
    extraGroups = ["networkmanager" "wheel"];
    hashedPasswordFile = "/etc/nixos/tylerg.passwd";
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
  ];

  # Enable the OpenSSH daemon. TODO: Remove root login and password login
  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # Vscode server
  services.vscode-server.enable = true;

  # FIX
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 9443];
  };

  #TODO: Move out
  # Docker + Portainer Setup
  # Enable system Docker (root)
  virtualisation.docker = {
    enable = true;
    extraOptions = "--dns 1.1.1.1 --dns 8.8.8.8";
  };

  # Use Docker backend for OCI containers
  virtualisation.oci-containers = {
    backend = "docker";
    containers.portainer = {
      image = "portainer/portainer-ce:latest";
      autoStart = true;
      ports = ["9443:9443"];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/home/tylerg/portainer-data:/data"
      ];
      user = "tylerg"; # container runs as root
    };
  };

  system.stateVersion = "25.05";
}
