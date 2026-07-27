# Cinevara medya merkezi — kaynağı ~/Projects/Cinevara (bkz. flake.nix
# inputs.cinevara). .desktop girdisini paket kendisi taşıyor, KDE menüsüne
# otomatik düşer.
{ pkgs, inputs, ... }:
{
  home.packages = [ inputs.cinevara.packages.${pkgs.system}.default ];
}
