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
    # Medya (iHD / VA-API ve oneVPL / Quick Sync üzerinden hızlandırmalı)
    mpv
    # nixpkgs'te normal ffmpeg VA-API içerir; QSV/oneVPL ise yalnızca full
    # varyantında derlenir. Çalışan Tumbleweed kurulumundaki vaapi + qsv
    # yeteneklerini birlikte korumak için full kullanılıyor.
    ffmpeg-full
    vlc

    # Yerel Markdown bilgi tabanı; vault: /home/can/llm-wiki
    obsidian

    # Firefox burada değil: politikalar ve eklentilerle birlikte
    # modules/nixos/firefox.nix içinde tanımlı.
    #
    # okular / gwenview / spectacle / kate zaten Plasma 6 modülünün varsayılan
    # paket setiyle geliyor — bu seti kırpmak için
    # modules/nixos/desktop.nix -> environment.plasma6.excludePackages.
  ];
}
