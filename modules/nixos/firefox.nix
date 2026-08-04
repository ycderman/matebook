# Firefox — bildirimsel politikalar ve eklentiler.
#
# Sistem seviyesinde tanımlı, çünkü policies/ExtensionSettings zaten makine
# geneli bir mekanizma ve wiki'nin Firefox sayfası bu modülü belgeliyor:
# https://wiki.nixos.org/wiki/Firefox
{ lib, pkgs, ... }:
let
  # AMO'daki bir eklentinin daima son sürümüne işaret eden indirme adresi.
  moz = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";

  # TV+ 1080p eklentisi: AMO'da yayınlanmayan, kendi imzalı .xpi dosyası.
  # Bu dosyayı depoya koyup `git add` yapman gerekiyor:
  #     modules/nixos/tvplus-1080p.xpi
  # Dosya yoksa aşağıdaki ExtensionSettings girdisi hiç üretilmez, yani derleme
  # kırılmaz — dosyayı ekleyip rebuild ettiğinde eklenti kendiliğinden gelir.
  tvplusXpi = ./tvplus-1080p.xpi;
in
{
  programs.firefox = {
    enable = true;

    # Türkçe dil paketi
    languagePacks = [ "tr" ];

    # Nixpkgs Firefox sarmalayıcısı Wayland'i zaten MOZ_ENABLE_WAYLAND=1 ile
    # varsayılan yapıyor. Firefox 153'te VA-API bu genel donanım çözme seçeneği
    # üzerinden yönetiliyor; eski media.ffmpeg.vaapi.enabled tercihini eklemek
    # gereksiz. "default" durumu, bir sürücü regresyonunda kullanıcının
    # about:config üzerinden geçici olarak kapatabilmesini sağlar.
    preferences = {
      "media.hardware-video-decoding.enabled" = true;
      "media.hardware-video-encoding.enabled" = true;

      # Bellek ayarı — makinede 8 GiB RAM var ve Firefox tek başına 2 GB PSS
      # kullanabiliyor. Aşağıdaki değerler ölçülen varsayılanlardan düşürüldü;
      # hepsi `preferencesStatus = "default"` olduğu için about:config'den
      # geri alınabilir.

      # bfcache: geri/ileri için bellekte tutulan tam sayfa kopyası sayısı.
      # Varsayılan -1, yani RAM'e göre otomatik ve bu makinede 8'e çıkıyor.
      "browser.sessionhistory.max_total_viewers" = 2;

      # Bellek içi HTTP önbelleği, KB. Varsayılan -1 (otomatik).
      "browser.cache.memory.capacity" = 65536;

      # İçerik process sayısı. Varsayılan 8; her process kendi JS heap'ini ve
      # temel yapılarını taşıdığı için sabit bir taban maliyeti var.
      # Bedeli: çok sekme aynı process'i paylaşır, biri çökerse hepsi gider ve
      # ağır bir sekme diğerlerini yavaşlatabilir.
      "dom.ipc.processCount" = 4;

      # Fission açıkken asıl belirleyici olan bu: aynı origin için açılan
      # izole process sayısı. Varsayılan 4.
      "dom.ipc.processCount.webIsolated" = 2;
    };
    preferencesStatus = "default";

    # Plasma Integration eklentisinin masaüstüyle konuşabilmesi için gerekli.
    # (Wiki: yerel mesajlaşma, imperatif kurulan Firefox'ta çalışmaz.)
    nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ];

    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };

      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = moz "ublock-origin";
          installation_mode = "normal_installed";
        };

        # Plasma Integration
        "plasma-browser-integration@kde.org" = {
          install_url = moz "plasma-integration";
          installation_mode = "normal_installed";
        };

        # Proton Pass — kimlik numarası AMO'nun kendi API'sinden doğrulandı
        # (addons.mozilla.org/api/v5/addons/addon/proton-pass -> guid).
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          install_url = moz "proton-pass";
          installation_mode = "normal_installed";
        };
      }
      # TV+ 1080p (AMO dışı, kendi imzalı) — yalnızca .xpi depoda varsa eklenir.
      // lib.optionalAttrs (builtins.pathExists tvplusXpi) {
        "tvplus-1080p@ycderman" = {
          install_url = "file://${tvplusXpi}";
          installation_mode = "normal_installed";
        };
      };
    };
  };
}
