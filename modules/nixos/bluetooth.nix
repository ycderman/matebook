# Bluetooth — Intel AX201 (USB 8087:0026, btusb).
# https://wiki.nixos.org/wiki/Bluetooth
{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        # Destekleyen cihazlarda pil seviyesi bildirimi.
        Experimental = true;
      };
    };
  };

  # Plasma'nın Bluetooth arayüzü bluedevil; ayrıca blueman kurulmuyor.
}
