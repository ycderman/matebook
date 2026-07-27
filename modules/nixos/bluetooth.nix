# Bluetooth — Intel AX201 (USB 8087:0026, btusb).
# https://wiki.nixos.org/wiki/Bluetooth
{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        # Battery level reporting for devices that support it (the Logitech
        # receiver on this machine already exposes hidpp_battery_0 over USB).
        Experimental = true;
      };
    };
  };

  # Plasma ships bluedevil as its Bluetooth front end, so no blueman here.
}
