# Power management for an 8 GiB Alder Lake-P laptop with no swap partition.
# https://wiki.nixos.org/wiki/Laptop
{ ... }:
{
  ##############################################################################
  # CPU / thermal
  ##############################################################################

  powerManagement.enable = true;

  # power-profiles-daemon over TLP: Plasma's battery applet talks to it
  # directly, so the power profile can be switched from the panel. The two
  # daemons manage the same knobs and must not run together — the wiki
  # recommends picking one and disabling the other.
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  # Intel thermal daemon — relevant for the i5-12450H under sustained load.
  services.thermald.enable = true;

  ##############################################################################
  # Suspend / lid
  ##############################################################################

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore"; # stay awake on the HDMI monitor
    HandlePowerKey = "suspend";
  };

  ##############################################################################
  # Swap — zram only, since the disk layout has no swap partition
  ##############################################################################
  # https://wiki.nixos.org/wiki/Swap

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # ~4 GiB of compressed swap on 8 GiB of RAM
  };

  # "When using zram for swap, it is highly recommended to enable a userspace
  #  OOM killer such as systemd-oomd."
  systemd.oomd.enable = true;

  # Hibernation is not possible without a swap device large enough to hold RAM;
  # this layout intentionally has none, so only suspend-to-idle is available.
}
