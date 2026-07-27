{
  description = "NixOS unstable (26.11) — HUAWEI MateBook D16 2024 (MCLF-XX) / Plasma 6";

  inputs = {
    # NixOS unstable channel — currently tracks the 26.11 development branch.
    # https://wiki.nixos.org/wiki/Flakes
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Home Manager must match the nixpkgs channel: unstable nixpkgs -> master.
    # https://wiki.nixos.org/wiki/Home_Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plasma-manager: declarative Plasma configuration as a Home Manager module.
    # Community project, linked from https://wiki.nixos.org/wiki/KDE
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.matebook = nixpkgs.lib.nixosSystem {
        inherit system;

        # Inputs are forwarded to every module so that host/feature modules can
        # reach home-manager and plasma-manager without importing the flake again.
        specialArgs = { inherit inputs self system; };

        modules = [ ./hosts/matebook ];
      };

      # nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
