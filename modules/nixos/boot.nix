# Önyükleyici — GRUB değil, systemd-boot (manual'ın UEFI için önerdiği seçenek).
#
# "The recommended option is systemd-boot: set the option
#  boot.loader.systemd-boot.enable to true."
#   -- https://nixos.org/manual/nixos/stable/#sec-installation-manual-installing
{ ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;

      # Boot menüsünün (ve 2 GiB'lik ESP'nin) eski kuşaklarla dolmasını önler;
      # eski kuşaklara `nixos-rebuild` üzerinden hâlâ dönülebilir.
      configurationLimit = 15;

      # Boot menüsü için ekranın kendi çözünürlüğünü kullan.
      consoleMode = "max";

      # Etkileşimli çekirdek komut satırı düzenleyicisini kapat: açık kalırsa
      # fiziksel erişimi olan biri init=/bin/sh ile root olabilir.
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # hardware.nix'teki fileSystems."/boot" ile aynı
    };

    # Açıkça kapalı: bu makine yalnızca UEFI ile açılıyor.
    grub.enable = false;

    timeout = 3;
  };

  # Sessiz açılış. Plasma'nın giriş yöneticisi neredeyse anında devralıyor.
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
  ];
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # NOT: burada i915.enable_guc parametresi YOK. Bu donanımda çekirdeğin zaten
  # adlp_guc + tgl_huc firmware'ini yükleyip GuC submission'ı açtığı dmesg ile
  # doğrulandı; parametreyi elle vermek gereksiz olurdu.

  boot.tmp.cleanOnBoot = true;
}
