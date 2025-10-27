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
  users.users.podman = {
    isSystemUser = true;
    isNormalUser = false;
    description = "Podman user";
    home = "/home/podman";
    createHome = true;
    group = "podman";
    uid = 993;
    linger = true;
  };

  virtualisation.docker = {
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # virtualisation.containers.enable = true;

  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings = {dns_enabled = true;};
  # };

  virtualisation.oci-containers = {
    containers.portainer = {
      image = "docker.io/portainer/portainer-ce:latest";
      autoStart = true;
      ports = ["9443:9443"];
      volumes = [
        "/home/podman/portainer:/data"
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
      user = "${toString config.users.users.podman.uid}"; # run rootless as podman user
    };
  };

  #Test nginx container
  virtualisation.oci-containers.containers.echo_test = {
    image = "docker.io/hashicorp/http-echo:latest";
    autoStart = true;
    ports = ["8080:5678"];
    cmd = [
      "-text=Hello from Podman rootless!"
    ];
    user = "${toString config.users.users.podman.uid}";
  };

  system.stateVersion = "25.05";
}
