# Kullanıcı hesapları.
{ pkgs, ... }:
{
  users.users.can = {
    isNormalUser = true;
    description = "Can Derman";
    shell = pkgs.bash;

    extraGroups = [
      "wheel" # sudo
      "networkmanager" # Plasma eklentisinden Wi-Fi yönetimi
      "video" # ekran parlaklığı (intel_backlight)
      "audio"
      "input"
      "i2c" # harici monitör parlaklığı, DDC/CI (bkz. graphics.nix)
    ];

    # Yalnızca ilk açılış parolası. İlk girişten hemen sonra `passwd` ile
    # değiştir; ya da tamamen bildirimsel bir hesap için bunu
    # `hashedPasswordFile` ile değiştirip users.mutableUsers = false yap.
    initialPassword = "nixos";
  };

  security.sudo = {
    enable = true;

    # wheel grubunun genel kuralı parolalı kalıyor: ileride başka bir yönetici
    # kullanıcı eklenirse ona otomatik olarak parolasız sudo verilmesin.
    wheelNeedsPassword = true;

    # `can` için parolasız sudo.
    #
    # Neden wheelNeedsPassword = false değil: o seçenek wheel grubunun tamamını
    # kapsardı; burada muafiyet tek kullanıcıya bağlı.
    #
    # Sıralama: nixpkgs'te wheel kuralı `mkOrder 600` ile tanımlı, kullanıcının
    # yazdığı extraRules ise varsayılan sırayla (1000) geliyor. Yani bu kural
    # sudoers dosyasına wheel kuralından SONRA yazılıyor ve sudo'da son eşleşen
    # kural geçerli olduğu için NOPASSWD kazanıyor.
    #
    # SETENV, wheel'in varsayılan kuralında da var; buraya yazılmazsa `can`
    # `sudo VAR=deger komut` yapma yetkisini kaybederdi.
    extraRules = [
      {
        users = [ "can" ];
        commands = [
          {
            command = "ALL";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];
  };

  # root parolası bilerek burada tanımlanmadı.
  #
  # Bildirimsel olarak ayarlansaydı (hashedPassword / initialPassword) her
  # `nixos-rebuild switch` bu değeri yeniden uygular ve elle `passwd root` ile
  # verilen parolayı sessizce geri alırdı. Tanımlanmadığı için root parolası
  # tamamen elle yönetiliyor: kurulumda `nixos-install`'ın sorduğu yerde
  # belirlenen parola kalıcı oluyor, sonradan `passwd root` ile değiştirilebiliyor.
  #
  # Bu ayrıca acil durum modunu (emergency shell) kullanılabilir tutuyor —
  # boot.loader.systemd-boot.editor = false olduğu için çekirdek satırını
  # düzenleyip root'a düşmek mümkün değil, geriye tek kurtarma yolu olarak
  # root parolası kalıyor.
}
