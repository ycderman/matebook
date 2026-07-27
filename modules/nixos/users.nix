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
    ];

    # Yalnızca ilk açılış parolası. İlk girişten hemen sonra `passwd` ile
    # değiştir; ya da tamamen bildirimsel bir hesap için bunu
    # `hashedPasswordFile` ile değiştirip users.mutableUsers = false yap.
    initialPassword = "nixos";
  };

  # wheel grubu için parolalı sudo.
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # root ile doğrudan giriş kapalı.
  users.users.root.hashedPassword = "!";
}
