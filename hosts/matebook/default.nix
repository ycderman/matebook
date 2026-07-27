# Makine giriş noktası: matebook
#
# Yeniden kullanılabilir her şey ../../modules/nixos altında; buraya yalnızca
# gerçekten bu makineye özgü bilgiler yazılır.
{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  networking.hostName = "matebook";

  # Bu makinenin ilk kurulduğu NixOS sürümü. Kurulu bir sistemde ASLA değiştirme —
  # durum tutan varsayılanları (veritabanı biçimleri, servis düzenleri) sabitler.
  # nixos-unstable 26.11'i izlerken kuruldu.
  system.stateVersion = "26.11";
}
