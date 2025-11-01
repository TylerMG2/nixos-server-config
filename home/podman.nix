{
  config,
  podmanUID,
  pkgs,
  ...
}: {
  home = {
    username = "podman";
    homeDirectory = "/home/podman";
    stateVersion = "24.11";
  };

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
            -p 8000:8000/tcp \
            -p 25565:25565/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start portainer";
      ExecStop = "${pkgs.podman}/bin/podman pod stop portainer";
      RestartSec = "1s";
    };
  };

  # Jellyfin pod
  systemd.user.services.pod-jellyfin = {
    Unit = {
      Description = "Rootless Podman Jellyfin Pod";
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
            --name jellyfin \
            --userns=host \
            -p 8096:8096/tcp \
            -p 8920:8920/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start jellyfin";
      ExecStop = "${pkgs.podman}/bin/podman pod stop jellyfin";
      RestartSec = "1s";
    };
  };

  # VPN Pod
  #TODO: It's probably worth it to move this pod and its containers to a seperate user
  #Then again, our portainer instance would no longer be able to see and manage these containers anymore
  systemd.user.services.pod-vpn = {
    Unit = {
      Description = "Rootless Podman VPN Pod for QBitTorrent";
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
            --name vpn \
            --userns=host \
            -p 8080:8080/tcp \
            -p 9696:9696/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start vpn";
      ExecStop = "${pkgs.podman}/bin/podman pod stop vpn";
      RestartSec = "1s";
    };
  };

  # Media providers pod
  systemd.user.services.pod-media = {
    Unit = {
      Description = "Rootless Podman Media Pod (Sonarr, Radarr, Lidarr, Prowlarr)";
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
            --name media \
            --userns=host \
            -p 8989:8989/tcp \
            -p 7878:7878/tcp \
            -p 8686:8686/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start media";
      ExecStop = "${pkgs.podman}/bin/podman pod stop media";
      RestartSec = "1s";
    };
  };

  services.podman = {
    enable = true;
    autoUpdate.enable = true;

    networks = {
      servarrnetwork = {
        driver = "bridge";
        subnet = "10.88.5.0/24";
        gateway = "10.88.5.1";
        autoStart = true;
        internal = false;
      };
    };

    containers = {
      portainer = {
        image = "docker.io/portainer/portainer-ce:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/portainer:/data"
          "/run/user/${toString podmanUID}/podman/podman.sock:/var/run/docker.sock"
        ];

        extraPodmanArgs = [
          "--pod=portainer"
          "--group-add=keep-groups"
        ];
      };

      # Minecraft server container
      minecraft = {
        image = "docker.io/itzg/minecraft-server:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/minecraft:/data:Z"
        ];

        environment = {
          EULA = "TRUE";
          MEMORY = "2G";
          PUID = "${toString podmanUID}";
          PGID = "1201"; #TODO Replace with variable alongside all below
        };

        extraPodmanArgs = [
          "--pod=portainer" #TODO: Use another pod
          "--group-add=keep-groups"
        ];
      };

      gluetun = {
        image = "docker.io/qmcgaw/gluetun:latest";
        autoStart = true;
        autoUpdate = "registry";
        volumes = ["/home/podman/gluetun:/gluetun"];
        environmentFile = ["/home/podman/gluetun.env"]; #TODO: Move most of these here and look into sops for secrets
        extraPodmanArgs = [
          "--pod=vpn"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--device=/dev/net/tun"
          "--health-cmd='ping -c 1 -W 5 8.8.8.8 || exit 1'"
          "--health-interval=20s"
          "--health-retries=5"
          "--health-timeout=10s"
          "--health-start-period=30s"
        ];
      };

      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/qbittorrent:/config" # config files
          "/home/podman/media/downloads:/downloads" # torrent download path
        ];

        environment = {
          PUID = "${toString podmanUID}";
          PGID = "1201";
          UMASK_SET = "022";
          WEBUI_PORT = "8080";
        };

        extraPodmanArgs = [
          "--pod=vpn"
          "--group-add=keep-groups"
          "--network=container:gluetun"
          "--requires=gluetun"
        ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/prowlarr:/config:Z"
        ];

        environment = {
          PUID = "${toString podmanUID}";
          PGID = "1201";
          TZ = "Australia/Melbourne";
        };

        extraPodmanArgs = [
          "--pod=vpn"
          "--group-add=keep-groups"
          "--network=container:gluetun"
          "--requires=gluetun"
        ];
      };

      jellyfin = {
        image = "docker.io/jellyfin/jellyfin:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/jellyfin/config:/config"
          "/home/podman/jellyfin/cache:/cache"
          "/home/podman/jellyfin/media:/media"
        ];

        environment = {
          TZ = "Australia/Melbourne";
          JELLYFIN_PublishedServerUrl = "http://your-server-ip:8096";
        };

        extraPodmanArgs = [
          "--pod=jellyfin"
          "--group-add=keep-groups"
        ];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        autoUpdate = "registry";
        volumes = [
          "/home/podman/sonarr:/config:Z"
          "/home/podman/jellyfin/media/tv:/tv"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "1201";
          TZ = "Australia/Melbourne";
        };
        extraPodmanArgs = [
          "--pod=media"
          "--group-add=keep-groups"
        ];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        autoUpdate = "registry";
        volumes = [
          "/home/podman/radarr:/config:Z"
          "/home/podman/jellyfin/media/movies:/movies"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "1201";
          TZ = "Australia/Melbourne";
        };
        extraPodmanArgs = [
          "--pod=media"
          "--group-add=keep-groups"
        ];
      };

      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        autoUpdate = "registry";
        volumes = [
          "/home/podman/lidarr:/config:Z"
          "/home/podman/jellyfin/media/music:/music"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "1201";
          TZ = "Australia/Melbourne";
        };
        extraPodmanArgs = [
          "--pod=media"
          "--group-add=keep-groups"
        ];
      };
    };
  };
}
