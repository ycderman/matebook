# Ağ — Intel AX201 (wlp0s20f3) NetworkManager tarafından yönetiliyor.
{ pkgs, ... }:
{
  networking = {
    networkmanager = {
      enable = true;

      # iwd, Intel kartlar için modern arka uç; wpa_supplicant ise NixOS
      # varsayılanı ve bu dizüstünün zaten bildiği ağlar arasında dolaşırken
      # daha az sorun çıkarıyor. Değiştirmek için: wifi.backend = "iwd";
      wifi = {
        backend = "wpa_supplicant";
        powersave = true; # pilde tasarruf
      };
    };

    # Plasma'nın kendi NetworkManager eklentisi (plasma-nm) var, ayrı bir tepsi
    # uygulamasına gerek yok.
    firewall = {
      enable = true;
      # KDE Connect portlarını programs.kdeconnect kendisi açıyor
      # (bkz. desktop.nix); bu dizüstünde başka dinleyen servis yok.
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };

    # Homeserver'a isimle erişmek için (iki tarafta /etc/hosts uğraşmadan).
    hosts = {
      "192.168.1.3" = [ "homeserver" ];
    };
  };

  # Yazıcılar ve homeserver için mDNS / .local keşfi.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Yalnızca OpenSSH istemcisi; dizüstünde sshd çalışmıyor. Homeserver'a mevcut
  # can@matebook anahtarıyla bağlanılıyor.
  programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    ethtool
    iw
    nmap
    dnsutils
  ];
}
