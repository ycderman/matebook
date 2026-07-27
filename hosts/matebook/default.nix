# Host entry point: matebook
#
# Everything reusable lives in ../../modules/nixos; only genuinely host-specific
# facts belong here.
{ ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  networking.hostName = "matebook";

  # The NixOS release this machine was first installed with. Never change it on
  # an existing system — it pins stateful defaults (databases, service layouts).
  # Installed from nixos-unstable while it tracked 26.11.
  system.stateVersion = "26.11";
}
