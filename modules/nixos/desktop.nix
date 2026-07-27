# KDE Plasma 6 on Wayland, with the new Plasma Login Manager instead of SDDM.
# https://wiki.nixos.org/wiki/KDE
{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;

  # Plasma's own login manager (the KDE replacement for SDDM).
  services.displayManager.plasma-login-manager.enable = true;

  # Plasma 6 runs on Wayland by default, so defaultSession is left unset.
  # Set it to "plasmax11" here if an X11 session is ever needed:
  # services.displayManager.defaultSession = "plasmax11";

  # No X server: only XWayland (pulled in by the Plasma 6 module) is used for
  # legacy applications.
  services.xserver.enable = false;

  # Trim the default Plasma package set.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa # music player — not used
    khelpcenter # offline KDE docs
    kwrited # wall/write message daemon
  ];

  # KDE Connect, including its firewall ports.
  programs.kdeconnect.enable = true;

  # Partition manager needs the polkit-backed helper service to be enabled.
  programs.partition-manager.enable = true;

  # Plasma applications that are *not* part of the plasma6 default set.
  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    kdePackages.kcalc
    kdePackages.ksystemlog
    kdePackages.isoimagewriter
    wl-clipboard
  ];

  # Portals for screen sharing and file dialogs under Wayland are configured by
  # the plasma6 module (xdg-desktop-portal-kde); nothing to add here.

  # Faster app startup / consistent theming for the few GTK apps in use.
  programs.dconf.enable = true;
}
