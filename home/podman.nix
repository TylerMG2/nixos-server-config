{
  config,
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
        "/run/user/${toString config.users.users.podman.uid}/podman/podman.sock:/var/run/docker.sock"
      ];

      # Keep group mappings
      extraPodmanArgs = ["--group-add=keep-groups"];
    };
  };
}
