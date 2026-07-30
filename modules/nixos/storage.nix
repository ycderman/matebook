# Uzak depolama: 192.168.1.3 adresindeki IdeaPad 530S homeserver.
#
# Bağlama tembel ve hatası ölümcül olmayan tutuluyor — erişilemeyen bir NFS
# sunucusu açılışı kilitleyebilir, bir dizüstünde istenen bu değil.
{ ... }:
{
  # NFS istemci desteği. (idmapd/rpc-statd zaten fileSystems girdileriyle
  # geliyor; rpcbind burada açık ki `showmount -e homeserver` da çalışsın.)
  services.rpcbind.enable = true;

  # homeserver:/srv/storage — sunucunun tek export'u, 192.168.1.0/24'e açık.
  # Adres bilerek düz IP: `homeserver` adı avahi üzerinden link-local IPv6'ya
  # (fe80::…) da çözülebiliyor ve o adresle NFS bağlanamıyor. Ayrıca bu sayede
  # bağlama avahi'nin hazır olmasına bağlı kalmıyor.
  fileSystems."/mnt/storage" = {
    device = "192.168.1.3:/srv/storage";
    fsType = "nfs";
    options = [
      "x-systemd.automount" # açılışta değil, ilk erişimde bağla
      "x-systemd.idle-timeout=600" # 10 dk kullanılmazsa çöz
      "noauto"
      "_netdev"
      # soft: BİLİNÇLİ TERCİH. hard olsaydı sunucu kapalıyken /mnt/storage'a
      # dokunan her süreç (Dolphin dahil) süresiz askıda kalırdı; soft ile
      # kısa bir bekleme sonrası hata dönüyor, masaüstü donmuyor. Bedeli:
      # yazma sırasında sunucu çökerse veri sessizce kaybolabilir — bu bağlama
      # üzerinden önemli yazma işi yaparken sunucunun ayakta olduğundan emin ol.
      "soft"
      "timeo=50"
    ];
  };

  # SSHFS alternatifi (matebook-homeserver-sshfs anahtarını kullanır):
  #   sshfs can@192.168.1.3:/srv /mnt/homeserver -o reconnect,idmap=user
  # sshfs ikilisi packages.nix içinde kurulu.
}
