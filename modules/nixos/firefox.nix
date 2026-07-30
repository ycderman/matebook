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
