# Locale, time zone and keyboard — mirrors the current setup of this machine
# (LANG=tr_TR.UTF-8, VC keymap trq, X11/Wayland layout tr).
{ ... }:
{
  time.timeZone = "Europe/Istanbul";

  i18n.defaultLocale = "tr_TR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
  };

  i18n.supportedLocales = [
    "tr_TR.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];

  # Virtual console: Turkish Q layout (same as the current `trq` keymap).
  console = {
    keyMap = "trq";
    earlySetup = true;
  };

  # XKB layout. Plasma's Wayland session reads this too, so it applies even
  # though no X server is enabled.
  services.xserver.xkb = {
    layout = "tr";
    variant = ""; # empty variant = Turkish Q
    model = "pc105";
  };

  # NTP — the Arch install had an unsynchronised clock; keep it fixed here.
  services.timesyncd.enable = true;
}
