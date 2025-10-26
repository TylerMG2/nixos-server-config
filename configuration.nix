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
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        dns = ["1.1.1.1" "8.8.8.8"];
      };
    };
  };

  # Create a dedicated docker user
  users.users.docker = {
    isNormalUser = true;
    linger = true;
    packages = with pkgs; [];
  };

  # Portainer container as dockerUser
  systemd.user.services.portainer = {
    description = "Portainer (rootless Docker)";
    after = ["network.target" "docker.socket"];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.docker}/bin/docker run --rm \
          --name portainer \
          -p 9443:9443 \
          -v $XDG_RUNTIME_DIR/docker.sock:/var/run/docker.sock \
          -v /home/docker/portainer-data:/data \
          portainer/portainer-ce:latest
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop portainer";
      Restart = "always";
      User = "docker";
    };
    wantedBy = ["default.target"];
  };

  system.stateVersion = "25.05";
}
