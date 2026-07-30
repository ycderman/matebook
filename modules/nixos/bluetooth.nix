# Bluetooth — Intel AX201 (USB 8087:0026, btusb).
# https://wiki.nixos.org/wiki/Bluetooth
{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        # Destekleyen cihazlarda pil seviyesi ve BlueZ deneysel D-Bus
        # arayüzleri. LE Audio codec desteği PipeWire/WirePlumber tarafında
        # kullanılabilir; çekirdeğin deneysel özellikleri zorlanmıyor.
        Experimental = true;
      };
    };
  };

  # NixOS'un pipewire paketi SBC/SBC-XQ, AAC, aptX ailesi, LDAC, LC3, mSBC,
  # FastStream ve Opus Bluetooth eklentileriyle derleniyor. WirePlumber tüm
  # kullanılabilir codec'leri ve donanım quirks veritabanını varsayılan olarak
  # kullanıyor; uyumsuz kulaklıklarda sorun çıkarabilecek global codec/kalite
  # zorlaması bu nedenle yapılmıyor.
  #
  # Plasma'nın Bluetooth arayüzü bluedevil; ayrıca blueman kurulmuyor.
}
