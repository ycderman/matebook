# Hardware profile — HUAWEI MateBook D16 2024
#
#   Board / DMI     : HUAWEI MCLF-XX (MateBook D, MCLF-XX-PCB, SKU C170, BIOS 1.13)
#   CPU             : 12th Gen Intel Core i5-12450H (Alder Lake-P, 8C/12T, intel_pstate)
#   GPU             : Intel Alder Lake-P GT1 [UHD Graphics] — PCI 8086:46a3
#   RAM             : 8 GiB (no swap partition -> zram, see modules/nixos/power.nix)
#   Storage         : WD PC SN740 512 GB NVMe (/dev/nvme0n1, 512110190592 bytes)
#   Wi-Fi           : Intel AX201 CNVi (iwlwifi) — wlp0s20f3
#   Bluetooth       : Intel AX201 Bluetooth (btusb, USB 8087:0026)
#   Audio           : Intel Alder Lake-P HDA + SOF DSP (sof-hda-dsp, Conexant codec)
#   Webcam          : Sunplus HD Camera (USB 1bcf:2d0c, uvcvideo)
#   Touchpad        : BLTP7840 I2C HID multitouch
#   Extras          : Huawei WMI hotkeys, intel_backlight, BAT0 (HB4692Z9ECW-22T)
#
# Written by hand from the running hardware instead of nixos-generate-config,
# so it is never overwritten. Layout follows the manual's UEFI/GPT scheme:
# https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  ##############################################################################
  # Kernel modules
  ##############################################################################

  # Needed inside the initrd to reach the NVMe root device.
  boot.initrd.availableKernelModules = [
    "xhci_pci" # Alder Lake PCH USB 3.2 xHCI
    "thunderbolt" # Alder Lake-P Thunderbolt 4 controller
    "nvme" # WD PC SN740 root disk
    "usb_storage" # USB installer / external drives
    "sd_mod"
  ];

  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [
    "kvm-intel" # VT-x is present (see lscpu flags)
    "huawei_wmi" # Huawei WMI hotkeys + battery charge thresholds
  ];

  boot.extraModulePackages = [ ];

  ##############################################################################
  # File systems — addressed by LABEL, never by UUID
  ##############################################################################
  #
  #   /dev/nvme0n1p1  2 GiB   vfat  LABEL=BOOT   -> /boot  (EFI System Partition)
  #   /dev/nvme0n1p2  rest    ext4  LABEL=nixos  -> /
  #
  # The manual recommends labels explicitly: "It is recommended that you assign
  # a unique symbolic label to the file system using the option -L label, since
  # this makes the file system configuration independent from device changes."

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [
      "noatime" # fewer writes on the NVMe
      "errors=remount-ro"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    # Equivalent of the manual's `mount -o umask=077`: keep the ESP unreadable
    # for non-root users, since it holds the unencrypted kernel/initrd.
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # No swap partition by design — compressed zram swap is used instead.
  swapDevices = [ ];

  ##############################################################################
  # Platform
  ##############################################################################

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 12th Gen Intel — microcode updates come from the redistributable firmware set.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # NetworkManager owns the interfaces (see modules/nixos/network.nix).
  networking.useDHCP = lib.mkDefault false;
}
