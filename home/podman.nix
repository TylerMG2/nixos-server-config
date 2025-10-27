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
