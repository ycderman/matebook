# AUR'daki Linux uyumluluk katmanını Nix paketi olarak açar.
{ ... }:
{
  nixpkgs.overlays = [
    (final: _prev: {
      openai-codex-desktop = final.callPackage ../../pkgs/openai-codex-desktop { };
    })
  ];
}
