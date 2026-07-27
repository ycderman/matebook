# Firmware — iwlwifi (AX201), btusb, i915 GuC/HuC blob'ları ve SOF ses DSP'si
# için gerekli; hepsi yeniden dağıtılabilir.
{ ... }:
{
  hardware.enableRedistributableFirmware = true;

  # UEFI/BIOS ve aygıt firmware güncellemeleri. HUAWEI LVFS'e yayın yapmıyor,
  # bu yüzden pratikte NVMe ve USB-C dock firmware'i için işe yarıyor.
  # https://wiki.nixos.org/wiki/Fwupd
  services.fwupd.enable = true;
}
