# mpv'nin varsayılanı donanım hızlandırma KAPALI (hwdec=no) — komut satırından
# --hwdec=auto verilmediği sürece (ör. dosya yöneticisinden çift tıklayınca
# mpv.desktop yalnızca `mpv --player-operation-mode=pseudo-gui -- %U` çalıştırır,
# hwdec bayrağı yok) yazılım decode'a düşer. Cinevara kendi --hwdec=auto-safe'ini
# zaten geçiyor, bu yalnızca dosya yöneticisi/terminalden doğrudan mpv açılışları
# için.
{ ... }:
{
  xdg.configFile."mpv/mpv.conf".text = ''
    hwdec=auto-safe
  '';

  xdg.configFile."mpv/input.conf".text = ''
    WHEEL_UP    nonscalable seek 5
    WHEEL_DOWN  nonscalable seek -5
  '';
}
