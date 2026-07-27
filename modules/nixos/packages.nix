# System-wide packages: tools that must exist before/without a user session.
# Anything user-facing belongs in modules/home/packages.nix instead.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Editors / basics
    vim
    git
    wget
    curl

    # Archives
    unzip
    zip
    p7zip

    # Hardware inspection — the tools used to build this configuration
    pciutils # lspci
    usbutils # lsusb
    lm_sensors
    dmidecode
    smartmontools
    nvme-cli
    powertop

    # Filesystem tooling for the ext4 root and the vfat ESP
    e2fsprogs
    dosfstools
    parted

    # Remote access to the homeserver (192.168.1.3)
    sshfs
    nfs-utils
    rsync
  ];

  # vim as the system editor for `sudoedit`, systemctl edit, etc.
  environment.variables.EDITOR = "vim";

  # SSD housekeeping for the WD PC SN740.
  services.fstrim.enable = true;

  # SMART monitoring of the NVMe. Results are readable with
  # `smartctl -a /dev/nvme0n1` and logged to the journal.
  services.smartd.enable = true;
}
