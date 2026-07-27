# Donanım profili — HUAWEI MateBook D16 2024
#
#   Anakart / DMI   : HUAWEI MCLF-XX (MateBook D, MCLF-XX-PCB, SKU C170, BIOS 1.13)
#   İşlemci         : 12. nesil Intel Core i5-12450H (Alder Lake-P, 8C/12T, intel_pstate)
#   Ekran kartı     : Intel Alder Lake-P GT1 [UHD Graphics] — PCI 8086:46a3
#   RAM             : 8 GiB (takas bölümü yok -> zram, bkz. modules/nixos/power.nix)
#   Depolama        : WD PC SN740 512 GB NVMe (/dev/nvme0n1, 512110190592 bayt)
#   Wi-Fi           : Intel AX201 CNVi (iwlwifi) — wlp0s20f3
#   Bluetooth       : Intel AX201 Bluetooth (btusb, USB 8087:0026)
#   Ses             : Intel Alder Lake-P HDA + SOF DSP (sof-hda-dsp, Conexant codec)
#   Kamera          : Sunplus HD Camera (USB 1bcf:2d0c, uvcvideo)
#   Dokunmatik yüzey: BLTP7840 I2C HID çoklu dokunma
#   Ekstra          : Huawei WMI kısayol tuşları, intel_backlight, BAT0 (HB4692Z9ECW-22T)
#
# Bu dosya nixos-generate-config çıktısı değil; çalışan sistemden okunan gerçek
# verilerle elle yazıldı, bu yüzden hiçbir zaman üzerine yazılmaz. Disk düzeni
# manual'daki UEFI/GPT şemasını izler:
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
  # Çekirdek modülleri
  ##############################################################################

  # initrd içinde NVMe kök diske ulaşmak için gerekenler.
  boot.initrd.availableKernelModules = [
    "xhci_pci" # Alder Lake PCH USB 3.2 xHCI
    "nvme" # WD PC SN740 kök disk
    "usb_storage" # USB kurulum medyası / harici diskler
    "sd_mod"
  ];

  # NOT: "thunderbolt" modülü bilinçli olarak YOK. Bu makinede Thunderbolt/USB4
  # bulunmuyor — donanımda doğrulandı:
  #   * /sys/bus/thunderbolt/devices dizini hiç oluşmuyor
  #   * lspci'de Thunderbolt NHI denetleyicisi yok (yalnızca 00:0d.0 "Thunderbolt 4
  #     USB Controller" var; bu, Type-C portunu süren TCSS xHCI denetleyicisi,
  #     Thunderbolt bağlantısı değil)
  #   * /sys/class/typec boş — USB-PD/alternatif mod denetleyicisi görünmüyor
  # Yani USB-C portu: şarj + DisplayPort + USB 3.2, Thunderbolt yok.

  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [
    "kvm-intel" # VT-x mevcut (lscpu bayraklarında görüldü)
    "huawei_wmi" # Huawei WMI kısayolları + pil şarj eşikleri
  ];

  boot.extraModulePackages = [ ];

  ##############################################################################
  # Dosya sistemleri — UUID değil, her zaman LABEL
  ##############################################################################
  #
  #   /dev/nvme0n1p1  2 GiB   vfat  LABEL=BOOT   -> /boot  (EFI Sistem Bölümü)
  #   /dev/nvme0n1p2  kalanı  ext4  LABEL=nixos  -> /
  #
  # Manual label kullanımını açıkça öneriyor: "It is recommended that you assign
  # a unique symbolic label to the file system using the option -L label, since
  # this makes the file system configuration independent from device changes."

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [
      "noatime" # NVMe'ye daha az yazma
      "errors=remount-ro"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    # Manual'daki `mount -o umask=077` karşılığı: şifrelenmemiş çekirdek ve
    # initrd'yi barındıran ESP'yi root dışındaki kullanıcılara kapalı tutar.
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Tasarım gereği takas bölümü yok — bunun yerine sıkıştırılmış zram kullanılıyor.
  swapDevices = [ ];

  ##############################################################################
  # Platform
  ##############################################################################

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 12. nesil Intel — mikrokod güncellemeleri redistributable firmware setinden gelir.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Arayüzleri NetworkManager yönetiyor (bkz. modules/nixos/network.nix).
  networking.useDHCP = lib.mkDefault false;
}
