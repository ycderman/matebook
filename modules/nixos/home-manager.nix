# Home Manager'ı NixOS modülü olarak bağlar; plasma-manager'ı da her kullanıcı
# yapılandırmasına açar.
# https://wiki.nixos.org/wiki/Home_Manager
{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    # İkinci bir nixpkgs değerlendirmek yerine sistemin (flake'te sabitlenmiş)
    # nixpkgs'ini kullan.
    useGlobalPkgs = true;

    # Kullanıcı paketlerini kullanıcı profiline kur.
    useUserPackages = true;

    # Önceden var olan dotfile'ları hata vermek yerine yeniden adlandır.
    backupFileExtension = "hm-bak";

    # Flake input'ları home modüllerine de ulaşsın.
    extraSpecialArgs = { inherit inputs; };

    # plasma-manager bir Home Manager modülü, NixOS modülü değil.
    # https://wiki.nixos.org/wiki/KDE
    sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];

    users.can = import ../home;
  };
}
