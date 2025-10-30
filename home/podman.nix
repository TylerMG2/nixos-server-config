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
            -p 8686:8686/tcp \
            -p 9696:9696/tcp
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
          "/home/podman/minecraft:/data"
        ];

        environment = {
          EULA = "TRUE";
          MEMORY = "2G";
        };

        extraPodmanArgs = [
          "--pod=portainer" #TODO: Use another pod
          "--group-add=keep-groups"
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
          "/home/podman/sonarr/config:/config"
          "/home/podman/jellyfin/media/tv:/tv"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "${toString podmanUID}";
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
          "/home/podman/radarr/config:/config"
          "/home/podman/jellyfin/media/movies:/movies"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "${toString podmanUID}";
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
          "/home/podman/lidarr/config:/config"
          "/home/podman/jellyfin/media/music:/music"
          "/home/podman/jellyfin/media/downloads:/downloads"
        ];
        environment = {
          PUID = "${toString podmanUID}";
          PGID = "${toString podmanUID}";
          TZ = "Australia/Melbourne";
        };
        extraPodmanArgs = [
          "--pod=media"
          "--group-add=keep-groups"
        ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        autoUpdate = "registry";

        volumes = [
          "/home/podman/prowlarr/config:/config"
        ];

        environment = {
          PUID = "${toString podmanUID}";
          PGID = "${toString podmanUID}";
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
