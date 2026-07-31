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
      # Portları modüllerin kendisi açıyor: KDE Connect'i programs.kdeconnect
      # (bkz. desktop.nix), 22'yi services.openssh.openFirewall (aşağıda),
      # mDNS'i services.avahi.openFirewall.
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };

    # Homeserver'a isimle erişmek için (iki tarafta /etc/hosts uğraşmadan).
    hosts = {
      "192.168.1.3" = [
        "homeserver"
        "candash"
      ];
    };
  };

  # Yazıcılar ve homeserver için mDNS / .local keşfi.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # İstemci tarafı: homeserver'a mevcut can@matebook anahtarıyla bağlanılıyor.
  programs.ssh.startAgent = true;

  # sshd — bu dizüstüne LAN'dan (192.168.1.2) bağlanmak için.
  #
  # DİKKAT: openFirewall bütün arayüzlerde 22'yi açıyor, yani kafe/otel Wi-Fi'ına
  # bağlanınca sshd o ağa da açık oluyor. Parola girişini kapatmak (aşağıya bkz.)
  # bunu kabul edilebilir kılan asıl önlem.
  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = "no";

      # Anahtarla giriş kurulana kadar açık. Bağlanacağın makinenin açık
      # anahtarını users.users.can.openssh.authorizedKeys.keys listesine ekleyip
      # burayı false yap — dizüstü dış ağlara çıktığı için asıl güvenlik bu.
      PasswordAuthentication = true;

      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  environment.systemPackages = with pkgs; [
    ethtool
    iw
    nmap
    dnsutils
  ];
}
