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

  users.groups.podman = {
    name = "podman";
    gid = 991;
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

    containers.storage.settings = {
      storage = {
        driver = "btrfs";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        options.overlay.mountopt = "nodev,metacopy=on";
      };
    };
  };

  # Create dirs for portainer
  systemd.tmpfiles.rules = [
    ''d /home/podman/portainer 0750 podman podman''
  ];

  # Portainer pod
  systemd.user.services.pod-portainer = {
    Unit = {
      Description = "Rootless Podman Portainer Pod";
      Wants = ["network-online.target"];
      After = ["network-online.target"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
    Service = {
      Type = "forking";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 2s"
        ''
          ${pkgs.podman}/bin/podman pod create --replace \
            --name portainer \
            --userns=host \
            -p 9443:9443/tcp \
            -p 9000:9000/tcp \
            -p 8000:8000/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start portainer";
      ExecStop = "${pkgs.podman}/bin/podman pod stop portainer";
      RestartSec = "1s";
    };
  };

  # Home manager
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      podmanUID = config.users.users.podman.uid;
    };
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.podman = import ./home/podman.nix;
  };

  # virtualisation.oci-containers = {
  #   containers.portainer = {
  #     image = "docker.io/portainer/portainer-ce:latest";
  #     autoStart = true;
  #     ports = ["9443:9443"];
  #     volumes = [
  #       "/home/podman/portainer:/data"
  #       "/run/user/${toString config.users.users.podman.uid}/podman/podman.sock:/var/run/docker.sock"
  #     ];
  #     user = "${toString config.users.users.podman.uid}"; # run rootless as podman user
  #   };
  # };

  # #Test nginx container
  # virtualisation.oci-containers.containers.echo_test = {
  #   image = "docker.io/hashicorp/http-echo:latest";
  #   autoStart = true;
  #   ports = ["8080:5678"];
  #   cmd = [
  #     "-text=Hello from Podman rootless!"
  #   ];
  #   user = "${toString config.users.users.podman.uid}";
  # };

  system.stateVersion = "25.05";
}
