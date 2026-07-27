# Networking — NetworkManager drives the Intel AX201 (wlp0s20f3).
{ pkgs, ... }:
{
  networking = {
    networkmanager = {
      enable = true;

      # iwd is the modern backend for Intel cards; wpa_supplicant remains the
      # NixOS default and is the safer choice for roaming between the Wi-Fi
      # networks this laptop already knows. Switch by setting: wifi.backend = "iwd";
      wifi = {
        backend = "wpa_supplicant";
        powersave = true; # laptop on battery
      };
    };

    # Plasma has its own NetworkManager applet (plasma-nm), so no extra tray app.
    firewall = {
      enable = true;
      # KDE Connect ports are opened automatically by programs.kdeconnect
      # (see desktop.nix); nothing else listens on this laptop.
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };

    # Resolve the homeserver by name without touching /etc/hosts on both sides.
    hosts = {
      "192.168.1.3" = [ "homeserver" ];
    };
  };

  # mDNS/.local discovery for printers and the homeserver.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # OpenSSH client only; no sshd on the laptop. The homeserver is reached with
  # the existing can@matebook key.
  programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    ethtool
    iw
    nmap
    dnsutils
  ];
}
