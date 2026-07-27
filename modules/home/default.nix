# Home Manager configuration for user `can`.
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

  # Same rule as system.stateVersion: set once, never bump on an existing home.
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
