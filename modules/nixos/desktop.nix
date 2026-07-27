# Wayland üzerinde KDE Plasma 6, SDDM yerine yeni Plasma Login Manager ile.
# https://wiki.nixos.org/wiki/KDE
{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;

  # Plasma'nın kendi giriş yöneticisi (KDE'nin SDDM yerine geçen bileşeni).
  services.displayManager.plasma-login-manager.enable = true;

  # Plasma 6 varsayılan olarak Wayland'de çalışır, bu yüzden defaultSession
  # ayarlanmadı. X11 oturumu gerekirse:
  # services.displayManager.defaultSession = "plasmax11";

  # X sunucusu yok: eski uygulamalar için yalnızca XWayland kullanılıyor
  # (plasma6 modülü kendisi getiriyor).
  services.xserver.enable = false;

  # Varsayılan Plasma paket setinden çıkarılanlar.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa # müzik oynatıcı — kullanılmıyor
    khelpcenter # çevrimdışı KDE yardım belgeleri
    kwrited # wall/write mesaj daemon'u
  ];

  # KDE Connect (güvenlik duvarı portlarını da kendisi açar).
  programs.kdeconnect.enable = true;

  # Bölüm yöneticisinin polkit tabanlı yardımcı servisi.
  programs.partition-manager.enable = true;

  # plasma6 varsayılan setinde OLMAYAN uygulamalar.
  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    kdePackages.kcalc
    kdePackages.ksystemlog
    kdePackages.isoimagewriter
    wl-clipboard
  ];

  # Wayland altında ekran paylaşımı ve dosya seçici için gereken portal'ları
  # (xdg-desktop-portal-kde) plasma6 modülü yapılandırıyor, ek bir şey gerekmiyor.

  # Az sayıdaki GTK uygulaması için tutarlı tema ve ayar depolama.
  programs.dconf.enable = true;
}
