# Intel ekran kartı — Alder Lake-P GT1 [UHD Graphics], PCI 8086:46a3 (Gen12).
# https://wiki.nixos.org/wiki/Intel_Graphics
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Wine için 32-bit GL

    extraPackages = with pkgs; [
      intel-media-driver # VA-API iHD: video decode/encode
      vpl-gpu-rt # oneVPL / Quick Sync çalışma zamanı (FFmpeg QSV)
      intel-compute-runtime # OpenCL + Level Zero; video codec sürücüsü değildir
    ];
  };

  # Gen12 için modern VA-API arka ucu iHD. Çalışan sistemde H.264, HEVC, VP9
  # ve MPEG-2 decode/encode ile AV1 decode bu sürücü üzerinden doğrulandı.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # i915.force_probe gerekmiyor: 8086:46a3 çekirdek tarafından hiçbir parametre
  # olmadan tanınıyor (bu makinede doğrulandı).
  # i915.enable_guc da gerekmiyor: bütün i915 parametreleri otomatikteyken
  # GuC submission/SLPC/RC ve HuC doğrulaması etkinleşiyor.

  # DDC/CI — harici monitörün (LG ULTRAGEAR, HDMI-A-1) parlaklık kontrolü.
  #
  # Bu kurulumda parlaklık için tek yol bu: kapak kapalı olduğundan dahili panel
  # eDP-1 devre dışı, dolayısıyla intel_backlight kullanılamıyor. I2C olmadan
  # PowerDevil hiç parlaklık kaynağı bulamıyor ve Plasma'daki kaydırıcı hiç
  # görünmüyor (libddcutil "Returned DDCA_Display_Ref list:" boş dönüyor).
  #
  # hardware.i2c.enable: i2c-dev modülünü yükler, i2c grubunu ve /dev/i2c-*
  # üzerinde oturum kullanıcısına ACL veren udev kuralını oluşturur.
  # Kullanıcının i2c grubuna eklenmesi users.nix içinde.
  #
  # Not: bu monitör VCP D6'yı (Power mode) desteklemiyor — okuma da yazma da
  # DDCRC_REPORTED_UNSUPPORTED dönüyor. Yani `ddcutil setvcp D6 04` ile
  # monitörü uyutmak mümkün değil, denenip doğrulandı. Sadece parlaklık çalışır.
  hardware.i2c.enable = true;

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo
    intel-gpu-tools # intel_gpu_top
    mesa-demos # glxinfo, glxgears (glxinfo paketi bunun içine taşındı)
    vulkan-tools
    ddcutil # DDC/CI: harici monitör parlaklığı
  ];
}
