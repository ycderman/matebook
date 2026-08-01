# `can` kullanıcısı için Home Manager yapılandırması.
{ config, ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./nix-shell-fix.nix
    ./git.nix
    ./llm-wiki.nix
    ./plasma.nix
    ./cinevara.nix
    ./mpv.nix
  ];

  home.username = "can";
  home.homeDirectory = "/home/can";

  # system.stateVersion ile aynı kural: bir kez ayarlanır, mevcut bir ev
  # dizininde sonradan yükseltilmez.
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "${config.home.homeDirectory}/Masaüstü";
    documents = "${config.home.homeDirectory}/Belgeler";
    download = "${config.home.homeDirectory}/İndirilenler";
    music = "${config.home.homeDirectory}/Müzik";
    pictures = "${config.home.homeDirectory}/Resimler";
    publicShare = "${config.home.homeDirectory}/Genel";
    templates = "${config.home.homeDirectory}/Şablonlar";
    videos = "${config.home.homeDirectory}/Videolar";
    projects = "${config.home.homeDirectory}/Projeler";
  };
}
