# Dil, saat dilimi ve klavye — her şey Türkçe.
#
# NOT: `nix-shell -p python3` komutunun verdiği
#     bash: export: `RANLİB=ranlib': not a valid identifier
# hatası sistem dili değiştirilerek DEĞİL, yalnızca nix komutlarını saran bir
# düzeltmeyle çözüldü. Bkz. modules/home/nix-shell-fix.nix
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
    # C.UTF-8 sistem dili olarak kullanılmıyor; yalnızca nix-shell-fix.nix'teki
    # sarmalayıcılar bunu kendi alt süreçlerine veriyor, o yüzden üretilmesi şart.
    "C.UTF-8/UTF-8"
  ];

  # Sanal konsol: Türkçe Q düzeni.
  console = {
    keyMap = "trq";
    earlySetup = true;
  };

  # XKB düzeni. Plasma'nın Wayland oturumu da bunu okur, X sunucusu açık olmasa
  # bile geçerlidir.
  services.xserver.xkb = {
    layout = "tr";
    variant = ""; # boş varyant = Türkçe Q
    model = "pc105";
  };

  # Saat eşitleme.
  services.timesyncd.enable = true;
}
