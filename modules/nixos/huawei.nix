# Makineye özel: HUAWEI WMI platform sürücüsü (huawei-wmi).
#
# Bu dizüstünde doğrulandı:
#   /sys/devices/platform/huawei-wmi/charge_control_thresholds  -> "80 85"
#   /sys/devices/platform/huawei-wmi/fn_lock_state              -> 0
#   /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold
#
# Modülün kendisi hardware.nix içinde yükleniyor (boot.kernelModules).
{ ... }:
{
  # Pil şarj eşikleri. Platform aygıtı belirdiği anda udev tarafından
  # uygulanıyor; böylece yeniden başlatmalarda ve modül yeniden yüklendiğinde
  # zamanlama yarışı olmadan geçerli kalıyor.
  #
  # Biçim "<başlangıç> <bitiş>": şarj <başlangıç>%'nin altında başlar,
  # <bitiş>%'de durur. Pili sürekli tam dolu tutmamak ömrünü uzatır; uzun bir
  # yolculuk öncesi limiti kaldırmak için ikisini de "0 100" yap.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="huawei-wmi", ATTR{charge_control_thresholds}="70 80"
  '';

  # Fn kilidi: 0 = medya tuşları birincil (şu anki davranış), 1 = F1..F12
  # birincil. Varsayılanı değiştirmek için aşağıyı aç.
  # systemd.tmpfiles.rules = [
  #   "w /sys/devices/platform/huawei-wmi/fn_lock_state - - - - 1"
  # ];

  # Huawei WMI kısayol tuşları sisteme normal bir girdi aygıtı olarak görünüyor
  # ("Huawei WMI hotkeys") ve Plasma tarafından işleniyor; ek eşleme gerekmiyor.
}
