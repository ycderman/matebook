# Aggregator for all system-level feature modules.
{ ... }:
{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./desktop.nix
    ./firmware.nix
    ./fonts.nix
    ./graphics.nix
    ./home-manager.nix
    ./huawei.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./packages.nix
    ./power.nix
    ./storage.nix
    ./users.nix
  ];
}
