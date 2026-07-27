# Machine-specific: HUAWEI WMI platform driver (huawei-wmi).
#
# Verified on this laptop:
#   /sys/devices/platform/huawei-wmi/charge_control_thresholds  -> "80 85"
#   /sys/devices/platform/huawei-wmi/fn_lock_state              -> 0
#   /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold
#
# The module itself is loaded from hardware.nix (boot.kernelModules).
{ ... }:
{
  # Battery charge thresholds. Applied by udev the moment the platform device
  # appears, so it survives reboots and module reloads without a timing race.
  #
  # Format is "<start> <end>": charging starts below <start>% and stops at
  # <end>%. Keeping the battery off a full charge extends its life; set both to
  # "0 100" to disable the limit before a trip.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="huawei-wmi", ATTR{charge_control_thresholds}="70 80"
  '';

  # Fn-lock: 0 = media keys are primary (current behaviour), 1 = F1..F12 are
  # primary. Uncomment to flip the default.
  # systemd.tmpfiles.rules = [
  #   "w /sys/devices/platform/huawei-wmi/fn_lock_state - - - - 1"
  # ];

  # The Huawei WMI hotkeys show up as a normal input device ("Huawei WMI
  # hotkeys") and are handled by Plasma; no extra key mapping needed.
}
