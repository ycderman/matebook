# Uzak depolama: 192.168.1.3 adresindeki IdeaPad 530S homeserver.
#
# Bağlamalar bilinçli olarak yorumlu bırakıldı — erişilemeyen bir NFS sunucusu
# açılışı kilitleyebilir. İhtiyacın olanı aç; aşağıdaki seçenekler bağlamayı
# tembel ve hatası ölümcül olmayan hâle getiriyor, bir dizüstünde istenen de bu.
{ ... }:
{
  # NFS istemci desteği. (idmapd/rpc-statd zaten fileSystems girdileriyle
  # geliyor; rpcbind burada açık ki `showmount -e homeserver` da çalışsın.)
  services.rpcbind.enable = true;

  # fileSystems."/mnt/homeserver" = {
  #   device = "homeserver:/srv/media";
  #   fsType = "nfs";
  #   options = [
  #     "x-systemd.automount"      # açılışta değil, ilk erişimde bağla
  #     "x-systemd.idle-timeout=600"
  #     "noauto"
  #     "_netdev"
  #     "soft"                     # sunucu kapalıysa asılı kalma, hata ver
  #     "timeo=50"
  #   ];
  # };

  # SSHFS alternatifi (matebook-homeserver-sshfs anahtarını kullanır):
  #   sshfs can@192.168.1.3:/srv /mnt/homeserver -o reconnect,idmap=user
  # sshfs ikilisi packages.nix içinde kurulu.
}
