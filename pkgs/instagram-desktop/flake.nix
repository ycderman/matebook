{
  description = "Instagram desktop client (WebKitGTK) with gallery-dl downloader";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      overlays.default = final: _prev: {
        instagram-desktop = final.callPackage ./default.nix { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        rec {
          instagram-desktop = pkgs.callPackage ./default.nix { };
          default = instagram-desktop;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.instagram-desktop ];
            packages = [
              pkgs.gallery-dl
              pkgs.ruff
            ];
            shellHook = ''
              echo "python src/instagram_desktop.py ile çalıştır"
            '';
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
