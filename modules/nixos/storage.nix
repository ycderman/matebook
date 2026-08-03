# Uzak depolama: 192.168.1.3 adresindeki IdeaPad 530S homeserver.
#
# Bağlama erişim anında (automount) ve hatası ölümcül olmayan tutuluyor —
# erişilemeyen bir NFS sunucusu masaüstünü kilitleyebilir, bir dizüstünde
# istenen bu değil. Bu yüzden her başarısızlık hızlıca hataya düşmeli.
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
      # Erişildiğinde bağla, 10 dk boşta kalınca çöz. Plasma'nın depolama
      # sorguları sunucu kapalıyken de bağlamayı tetikliyor; aşağıdaki
      # retry=0 + mount-timeout ikilisi bu denemeyi saniyeler içinde
      # başarısız kılıyor, böylece Dolphin autofs_wait'te kilitlenmiyor.
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      # Bağlama denemesini 10 sn'de kes. Varsayılan 90 sn, ve o süre boyunca
      # tekrar tekrar tetiklenen başarısız denemeler automount birimini
      # düşürüp /mnt/storage'ı sessizce ölü bırakabiliyor.
      "x-systemd.mount-timeout=10"
      "noauto"
      "_netdev"
      # NFSv4'e sabitle: sürüm pazarlığı v3'e düşerse rpcbind (port 111)
      # gerekiyor, sunucuda kapalı ve mount orada takılıyor.
      "nfsvers=4.2"
      # soft: BİLİNÇLİ TERCİH. hard olsaydı sunucu kapalıyken /mnt/storage'a
      # dokunan her süreç (Dolphin dahil) süresiz askıda kalırdı; soft ile
      # kısa bir bekleme sonrası hata dönüyor, masaüstü donmuyor. Bedeli:
      # yazma sırasında sunucu çökerse veri sessizce kaybolabilir — bu bağlama
      # üzerinden önemli yazma işi yaparken sunucunun ayakta olduğundan emin ol.
      "soft"
      "timeo=50"
      "retry=0" # ilk bağlantı başarısızsa dakikalarca yeniden deneme
    ];
  };

  # SSHFS alternatifi (matebook-homeserver-sshfs anahtarını kullanır):
  #   sshfs can@192.168.1.3:/srv /mnt/homeserver -o reconnect,idmap=user
  # sshfs ikilisi packages.nix içinde kurulu.
}
