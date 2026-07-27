# Boot loader — systemd-boot (the manual's recommended UEFI loader), not GRUB.
#
# "The recommended option is systemd-boot: set the option
#  boot.loader.systemd-boot.enable to true."
#   -- https://nixos.org/manual/nixos/stable/#sec-installation-manual-installing
{ ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;

      # Keep the boot menu (and the 2 GiB ESP) from filling up with old
      # generations; older generations stay reachable via `nixos-rebuild`.
      configurationLimit = 15;

      # Use the panel's native resolution for the boot menu.
      consoleMode = "max";

      # Disable the interactive kernel command line editor: without it, anyone
      # with physical access can boot with init=/bin/sh and become root.
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # matches fileSystems."/boot" in hardware.nix
    };

    # Explicitly off: this machine boots UEFI only.
    grub.enable = false;

    timeout = 3;
  };

  # Quiet boot. Plasma's login manager takes over almost immediately.
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
  ];
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  # Note: no i915.enable_guc parameter here. Verified on this hardware that the
  # kernel already loads adlp_guc + tgl_huc and enables GuC submission by
  # default on Alder Lake-P, so forcing it would be redundant.

  boot.tmp.cleanOnBoot = true;
}
