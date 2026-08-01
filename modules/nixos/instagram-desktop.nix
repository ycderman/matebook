# WebKitGTK tabanlı Instagram istemcisi; indirme tarafını gallery-dl yapıyor.
{ ... }:
{
  nixpkgs.overlays = [
    (final: _prev: {
      instagram-desktop = final.callPackage ../../pkgs/instagram-desktop { };
    })
  ];
}
