# plasma-manager ile bildirimsel Plasma 6 yapılandırması.
#
# NixOS Wiki'nin KDE sayfası şunu söylüyor: "With plasma-manager, it is possible
# to make Plasma configurations via nix by providing home-manager modules" ve
# "Plasma-Manager is a community project" — yani nixpkgs'in parçası değil,
# seçenek kümesi NixOS'tan bağımsız sürümleniyor. Bu dosya bilinçli olarak dar
# tutuldu; burada tanımlanmayan her şeyi Plasma kendi yönetiyor.
#
# Sistem ayarlarından elle yaptığın değişiklikleri Nix'e dökmek için:
#   nix run github:nix-community/plasma-manager
# (rc2nix, mevcut Plasma rc dosyalarını programs.plasma seçeneklerine çevirir.)
{ ... }:
{
  programs.plasma = {
    enable = true;

    # `overrideConfig = true` olsaydı, burada tanımlanmayan her ayar her
    # etkinleştirmede silinirdi. Masaüstü elle de ayarlanabilsin diye kapalı.
    overrideConfig = false;

    ############################################################################
    # Görünüm
    ############################################################################
    workspace = {
      # "select" = tek tıklama seçer, çift tıklama açar (klasik davranış).
      # Diğer geçerli değer "open": tek tıklama doğrudan açar.
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";

      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };

      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/…";
    };

    ############################################################################
    # Panel — 1920x1080 dizüstü ekranı için tek alt panel
    ############################################################################
    #
    # Sıralama soldan sağa. Uygulama menüsünden hemen sonraki ilk ikon Konsole.
    # (Sanal masaüstü değiştirici/pager panelden çıkarıldı ki Konsole gerçekten
    # ilk ikon olsun; masaüstleri arasında Meta+1..4 ile geçilebiliyor.)
    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          "org.kde.plasma.kickoff"
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.konsole.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
              ];
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];

    ############################################################################
    # Pencere yöneticisi
    ############################################################################
    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 1;
      };
    };

    ############################################################################
    # Kısayollar
    ############################################################################
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Konsole";
        key = "Meta+Return";
        command = "konsole";
      };
      "launch-dolphin" = {
        name = "Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
    };

    shortcuts = {
      "kwin"."Switch to Desktop 1" = "Meta+1";
      "kwin"."Switch to Desktop 2" = "Meta+2";
      "kwin"."Switch to Desktop 3" = "Meta+3";
      "kwin"."Switch to Desktop 4" = "Meta+4";
      "kwin"."Window Maximize" = "Meta+Up";
      "kwin"."Window Minimize" = "Meta+Down";
    };

    ############################################################################
    # Ekran kilidi — tamamen kapalı
    ############################################################################
    #
    # Ekran hiçbir zaman kilitlenmez: ne boşta kalınca, ne uyanışta, ne açılışta.
    # (Açılıştaki Plasma Login Manager girişi bundan bağımsız, o duruyor.)
    kscreenlocker = {
      autoLock = false;
      lockOnResume = false;
      lockOnStartup = false;
    };

    ############################################################################
    # Güç yönetimi — asla uyuma, 10 dakika sonra yalnızca ekranı kapat
    ############################################################################
    #
    # Üç profil de (prize takılı / pil / pil azken) aynı davranışta, çünkü
    # istenen "hiçbir zaman uykuya geçmesin". Bunun sistem tarafındaki eşi
    # modules/nixos/power.nix içindeki services.logind.settings.Login ayarları;
    # ikisi birlikte çalışmalı.
    #
    # Not: batteryLevels.criticalAction bilerek ayarlanmadı — pil kritik
    # seviyeye düştüğünde Plasma'nın varsayılan koruması (veri kaybını önlemek
    # için kapanma) devrede kalsın.
    powerdevil =
      let
        asla = {
          # Otomatik askıya alma yok.
          autoSuspend.action = "nothing";

          # Kapak kapatılınca hiçbir şey yapma — bilgisayar çalışmaya devam eder.
          whenLaptopLidClosed = "doNothing";

          # 10 dakika (600 saniye) hareketsizlikten sonra yalnızca ekranı kapat.
          turnOffDisplay.idleTimeout = 600;

          # Ekranı önceden karartma; tek adımda kapansın.
          dimDisplay.enable = false;

          # Güç tuşu Plasma'nın oturum kapatma ekranını açsın.
          powerButtonAction = "showLogoutScreen";
        };
      in
      {
        AC = asla;
        battery = asla;
        lowBattery = asla;
      };

    ############################################################################
    # Karşılığı olan seçeneği bulunmayan ayarlar için ham rc girdileri
    ############################################################################
    configFile = {
      # Baloo dosya indeksleyicisi 8 GiB'lik bir makinede arka planda en çok
      # disk/CPU yiyen bileşen; uygulama araması bundan etkilenmiyor.
      "baloofilerc"."Basic Settings"."Indexing-Enabled".value = false;

      # Varsayılan tarayıcı (modules/nixos/firefox.nix ile kurulan Firefox).
      "kdeglobals"."General"."BrowserApplication".value = "firefox.desktop";
    };
  };
}
