{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = {
    self,
    nixpkgs,
    vscode-server,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {system = system;};
  in {
    nixosConfigurations.home-server = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        vscode-server.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
