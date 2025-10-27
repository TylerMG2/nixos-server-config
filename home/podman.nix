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
            -p 8000:8000/tcp
        ''
      ];
      ExecStart = "${pkgs.podman}/bin/podman pod start portainer";
      ExecStop = "${pkgs.podman}/bin/podman pod stop portainer";
      RestartSec = "1s";
    };
  };

  services.podman = {
    enable = true;
    autoUpdate.enable = true;

    containers.portainer = {
      image = "docker.io/portainer/portainer-ce:latest";
      autoStart = true;
      autoUpdate = "registry";

      # We'll mount volumes but ignore ports for now
      volumes = [
        "/home/podman/portainer:/data"
        # Rootless Podman socket path:
        "/run/user/${toString podmanUID}/podman/podman.sock:/var/run/docker.sock"
      ];

      # Keep group mappings
      extraPodmanArgs = [
        "--pod=portainer"
        "--group-add=keep-groups"
      ];
    };
  };
}
