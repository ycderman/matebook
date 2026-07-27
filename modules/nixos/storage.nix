# Remote storage: the IdeaPad 530S homeserver at 192.168.1.3.
#
# The mounts are left commented out on purpose — an unreachable NFS server can
# stall boot. Uncomment what is needed; the x-systemd.automount options below
# make the mount lazy and non-fatal, which is what a laptop wants.
{ ... }:
{
  # NFS client support (rpcbind + idmapd are pulled in by the fileSystems
  # entries; rpcbind is enabled here so `showmount -e homeserver` works too).
  services.rpcbind.enable = true;

  # fileSystems."/mnt/homeserver" = {
  #   device = "homeserver:/srv/media";
  #   fsType = "nfs";
  #   options = [
  #     "x-systemd.automount"      # mount on first access, not at boot
  #     "x-systemd.idle-timeout=600"
  #     "noauto"
  #     "_netdev"
  #     "soft"                     # fail instead of hanging when the server is down
  #     "timeo=50"
  #   ];
  # };

  # SSHFS alternative (uses the matebook-homeserver-sshfs key):
  #   sshfs can@192.168.1.3:/srv /mnt/homeserver -o reconnect,idmap=user
  # The sshfs binary is installed in packages.nix.
}
