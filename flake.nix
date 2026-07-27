{
  description = "NixOS unstable (26.11) — HUAWEI MateBook D16 2024 (MCLF-XX) / Plasma 6";

  inputs = {
    # NixOS unstable kanalı — şu anda 26.11 geliştirme dalını izliyor.
    # https://wiki.nixos.org/wiki/Flakes
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Home Manager, nixpkgs kanalıyla eşleşmeli: unstable nixpkgs -> master dalı.
    # https://wiki.nixos.org/wiki/Home_Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plasma-manager: Plasma'yı bildirimsel yapılandıran Home Manager modülü.
    # Topluluk projesi; https://wiki.nixos.org/wiki/KDE sayfasından bağlanıyor.
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

        # Input'lar her modüle iletiliyor; böylece makine/özellik modülleri
        # flake'i tekrar import etmeden home-manager ve plasma-manager'a ulaşıyor.
        specialArgs = { inherit inputs self system; };

        modules = [ ./hosts/matebook ];
      };

      # nix fmt
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
