# Kullanıcı seviyesindeki paketler. Sistem araçları modules/nixos/packages.nix'te.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminal
    btop
    fastfetch
    ripgrep
    fd
    eza
    bat
    jq
    tree
    ncdu
    bubblewrap
    # Medya (iHD / VA-API üzerinden donanım hızlandırmalı)
    mpv
    ffmpeg
    vlc
    # Claude Desktop — paket tanımı ../../pkgs/claude-desktop,
    # overlay modules/nixos/claude-desktop.nix'te.
    claude-desktop

    # Firefox burada değil: politikalar ve eklentilerle birlikte
    # modules/nixos/firefox.nix içinde tanımlı.
    #
    # okular / gwenview / spectacle / kate zaten Plasma 6 modülünün varsayılan
    # paket setiyle geliyor — bu seti kırpmak için
    # modules/nixos/desktop.nix -> environment.plasma6.excludePackages.
  ];
}
