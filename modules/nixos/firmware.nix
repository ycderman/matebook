# Firmware — needed for iwlwifi (AX201), btusb, the i915 GuC/HuC blobs and the
# SOF audio DSP, all of which are redistributable.
{ ... }:
{
  hardware.enableRedistributableFirmware = true;

  # UEFI/BIOS and device firmware updates. HUAWEI does not publish to LVFS, so
  # this mostly serves the NVMe and any USB-C dock firmware.
  # https://wiki.nixos.org/wiki/Fwupd
  services.fwupd.enable = true;
}
