# `can` kullanıcısı için Home Manager yapılandırması.
{ ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./plasma.nix
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
  };
}
