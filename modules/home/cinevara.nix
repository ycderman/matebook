# Cinevara medya merkezi — kaynağı github:ycderman/Cinevara (bkz. flake.nix
# inputs.cinevara; depo public, kimlik gerekmez). .desktop girdisini
# paket kendisi taşıyor, KDE menüsüne otomatik düşer.
#
# Yerel geliştirme: commit'lenmemiş değişiklikleri denemek için
#   rebuild-test --override-input cinevara path:$HOME/Projects/Cinevara
{ pkgs, inputs, ... }:
{
  # pkgs.system kullanılmıyor: nixpkgs onu stdenv.hostPlatform.system lehine
  # kullanımdan kaldırdı (eval uyarısı veriyor).
  home.packages = [ inputs.cinevara.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
