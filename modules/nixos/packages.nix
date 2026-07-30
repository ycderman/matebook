# Sistem geneli paketler: kullanıcı oturumu olmadan da gerekebilecek araçlar.
# Kullanıcıya dönük her şey modules/home/packages.nix içinde.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Temel
    nano
    git
    wget
    curl
    # Arşiv
    unzip
    zip
    p7zip
    # Donanım inceleme — bu yapılandırmayı çıkarırken kullanılan araçlar
    pciutils # lspci
    usbutils # lsusb
    lm_sensors
    dmidecode
    smartmontools
    nvme-cli
    powertop
    # ext4 kök ve vfat ESP için dosya sistemi araçları
    e2fsprogs
    dosfstools
    parted
    # Homeserver'a (192.168.1.3) erişim
    sshfs
    nfs-utils
    rsync
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  # sudoedit, `systemctl edit`, git vb. için sistem düzenleyicisi nano.
  # EDITOR/VISUAL'ın tek tanım yeri burası — home tarafında tekrarlanmıyor.
  environment.variables.EDITOR = "nano";
  environment.variables.VISUAL = "nano";
  # WD PC SN740 için SSD bakımı.
  services.fstrim.enable = true;
  # NVMe'nin SMART izlemesi. Sonuçlar `smartctl -a /dev/nvme0n1` ile okunur,
  # ayrıca journal'a yazılır.
  services.smartd.enable = true;
}
