# Güç yönetimi.
#
# İSTENEN DAVRANIŞ: bilgisayar hiçbir zaman kendiliğinden uykuya geçmez, kapak
# kapatıldığında çalışmaya devam eder, ekran 10 dakika hareketsizlikten sonra
# yalnızca kapanır (kilitlenmez).
#
# Bu davranışın iki ayağı var:
#   * systemd-logind  -> aşağıdaki ayarlar (oturum açık olmasa da geçerli)
#   * Plasma/powerdevil -> modules/home/plasma.nix içindeki powerdevil bölümü
# İkisi de aynı yönde ayarlanmazsa biri diğerini bastırır.
#
# https://wiki.nixos.org/wiki/Laptop
{ ... }:
{
  ##############################################################################
  # İşlemci / sıcaklık
  ##############################################################################

  powerManagement.enable = true;

  # TLP değil power-profiles-daemon: Plasma'nın pil eklentisi doğrudan bununla
  # konuşuyor, güç profili panelden değiştirilebiliyor. İkisi aynı ayarları
  # yönettiği için birlikte çalıştırılmamalı — wiki birini seçip diğerini
  # kapatmayı öneriyor.
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  # Intel termal daemon — i5-12450H sürekli yük altındayken önemli.
  services.thermald.enable = true;

  ##############################################################################
  # Kapak ve güç tuşu — otomatik uyku tamamen kapalı
  ##############################################################################

  services.logind.settings.Login = {
    # Kapak kapalıyken çalışmaya devam et (harici ekran bağlı olsun olmasın).
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";

    # Güç tuşuna basınca logind karışmasın; Plasma kendi oturum kapatma
    # ekranını gösterir (bkz. plasma.nix -> powerdevil.*.powerButtonAction).
    HandlePowerKey = "ignore";

    # Boşta kalınca hiçbir şey yapma.
    IdleAction = "ignore";
  };

  # Elle uyku (Plasma menüsünden "Askıya al") hâlâ mümkün; kapatılan yalnızca
  # otomatik/olaya bağlı uyku.

  ##############################################################################
  # Takas — disk düzeninde takas bölümü olmadığı için yalnızca zram
  ##############################################################################
  # https://wiki.nixos.org/wiki/Swap

  zramSwap = {
    enable = true;
    algorithm = "zstd";

    # RAM ile aynı boyut: 8 GiB RAM -> 8 GiB zram aygıtı. Bu, aygıtın azami
    # boyutu; sıkıştırılmış veri yalnızca gerçekten kullanıldığı kadar RAM tutar.
    memoryPercent = 100;
  };

  # "When using zram for swap, it is highly recommended to enable a userspace
  #  OOM killer such as systemd-oomd."
  #
  # enable tek başına yalnızca daemon'u başlatıyor; hangi cgroup'ları
  # yöneteceği söylenmezse RAM/takas dolduğunda hiçbir şeye müdahale etmiyor
  # (yaşandı: bellek dolduğunda oomd hiç devreye girmedi). Bu iki seçenek
  # takas baskısı izlemeyi kök slice'a, bellek baskısı izlemeyi kullanıcı
  # slice'larına bağlıyor. Kurulumdan sonra `oomctl` ile doğrula.
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # Hazırda bekletme (hibernate) bu düzende mümkün değil: RAM'i sığdıracak bir
  # takas aygıtı yok ve zram'e hibernate yapılamaz.
}
