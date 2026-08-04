# Uzak depolama: 192.168.1.3 adresindeki IdeaPad 530S homeserver.
#
# Bağlama erişim anında (automount) ve hatası ölümcül olmayan tutuluyor —
# erişilemeyen bir NFS sunucusu masaüstünü kilitleyebilir, bir dizüstünde
# istenen bu değil. Bu yüzden her başarısızlık hızlıca hataya düşmeli.
{ config, pkgs, lib, ... }:
{
  # rpcbind kapalı. Portmapper'a yalnızca NFSv2/v3 ihtiyaç duyar; bu bağlama
  # NFSv4.2'ye sabitlenmiştir (aşağıya bakın) ve sunucu da NFSv2/v3'ü kapatıp
  # port 111'i kapalı tutar.
  #
  # mkForce gerekiyor: nixpkgs'in `tasks/filesystems/nfs.nix` modülü, NFS
  # dosya sistemi tanımlandığı anda `services.rpcbind.enable = true` değerini
  # koşulsuz atıyor.
  #
  # Burada daha önce `services.rpcbind.enable = true` vardı ve gerekçesi
  # `showmount -e homeserver` komutunun çalışmasıydı. O komut sunucuda port
  # 111 kapalı olduğu için zaten çalışmıyordu; ayar yalnızca dizüstünde
  # gereksiz bir dinleyici açıyordu. Export listesi gerekirse sunucudan:
  # `showmount -e localhost`.
  services.rpcbind.enable = lib.mkForce false;

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

  # Automount tetikleyicisini yalnızca sunucu cevap verirken kur.
  #
  # Sorun: autofs tetikleyicisi kurulu olduğu sürece /mnt/storage'a dokunan
  # her süreç (Dolphin, Plasma'nın solid sorguları, xdg-desktop-portal)
  # bağlama denemesi bitene kadar çekirdekte bloke oluyor. Sunucu kapalıyken
  # bu, mount-timeout kadar tam donma demek — ölçüldü: 10.1 sn.
  #
  # Çözüm: sunucuya erişilemiyorsa automount birimini durdur. O anda
  # /mnt/storage sıradan bir boş dizin olur, stat anında döner, Dolphin
  # donmaz. Sunucu geri geldiğinde tetikleyici yeniden kurulur.
  systemd.services.storage-automount-gate = {
    description = "Arm /mnt/storage automount only while the homeserver answers";
    after = [ "network.target" ];
    path = [
      pkgs.bash
      pkgs.coreutils
      config.systemd.package
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      if timeout 2 bash -c 'exec 3<>/dev/tcp/192.168.1.3/2049' 2>/dev/null; then
        systemctl start mnt-storage.automount
      elif ! systemctl is-active --quiet mnt-storage.mount; then
        # Zaten bağlıysa dokunma: soft bağlama erişim hatası döndürür,
        # bu da askıda kalmaktan iyidir.
        systemctl stop mnt-storage.automount
      fi
    '';
  };

  systemd.timers.storage-automount-gate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };

  # /mnt/homeserver için aynı kapı: gerekçe yukarıdaki storage gate ile
  # birebir aynı, yalnızca yoklanan port SSH (22).
  systemd.services.homeserver-automount-gate = {
    description = "Arm /mnt/homeserver automount only while the homeserver answers";
    after = [ "network.target" ];
    path = [
      pkgs.bash
      pkgs.coreutils
      config.systemd.package
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      if timeout 2 bash -c 'exec 3<>/dev/tcp/192.168.1.3/22' 2>/dev/null; then
        systemctl start mnt-homeserver.automount
      elif ! systemctl is-active --quiet mnt-homeserver.mount; then
        systemctl stop mnt-homeserver.automount
      fi
    '';
  };

  systemd.timers.homeserver-automount-gate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
    };
  };

  # homeserver:/home/can — sunucunun ev dizini.
  #
  # NFS değil SSHFS: sunucunun tek NFS export'u tüm 192.168.1.0/24'e açık ve
  # all_squash ile uid 1000'e eşleniyor. Ev dizini SSH anahtarları, git
  # kimlik bilgileri ve yapılandırma deposu içeriyor; onu aynı kimlik
  # doğrulamasız export'a koymak LAN'daki herkese okuma hakkı verirdi.
  # SSHFS kimlik doğrulamalı ve şifreli, ekstra port açmıyor.
  #
  # Bağlamayı systemd (root) yapıyor, bu yüzden anahtar ve known_hosts
  # açıkça veriliyor — root'un kendi ~/.ssh'ı kullanılmıyor.
  fileSystems."/mnt/homeserver" = {
    device = "can@192.168.1.3:/home/can";
    fsType = "sshfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "noauto"
      "_netdev"
      # allow_other: bağlamayı root yapıyor, erişecek olan `can`.
      # uid/gid iki tarafta da 1000/100, bu yüzden eşleme gerekmiyor.
      "allow_other"
      "default_permissions"
      "reconnect"
      "IdentityFile=/home/can/.ssh/homeserver-termius-ed25519"
      "IdentitiesOnly=yes"
      "UserKnownHostsFile=/etc/ssh/ssh_known_hosts"
      "StrictHostKeyChecking=yes"
      # /mnt/storage ile aynı gerekçe: sunucu kapalıyken bağlama denemesi
      # dakikalarca sürmesin, saniyeler içinde hataya düşsün.
      "ConnectTimeout=5"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      # LAN'da sıkıştırma yavaşlatır.
      "Compression=no"
    ];
  };

  # mount.sshfs helper'ının bağlama sırasında bulunabilmesi için.
  system.fsPackages = [ pkgs.sshfs ];

  # StrictHostKeyChecking=yes ile bağlama, root'un TOFU yapamayacağı için
  # host anahtarını deklaratif tutuyor.
  programs.ssh.knownHosts.homeserver = {
    hostNames = [ "192.168.1.3" "homeserver" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/ZQWYDyspWfn+EiCd5QYzv0lHPU2+jdc+yd+3uG8Bp";
  };
}
