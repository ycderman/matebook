# Dil, saat dilimi ve klavye.
# Sistem ve konsol dili Türkçe kalır; yalnızca büyük/küçük harf dönüşümü ayrılır.
{ ... }:
{
  time.timeZone = "Europe/Istanbul";

  # Arayüz dili, tarih/saat, para birimi vs. Türkçe.
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

    ############################################################################
    # `nix-shell -p python3` hatasının çözümü
    ############################################################################
    #
    #   bash: export: `RANLİB=ranlib': not a valid identifier
    #
    # Sebep: nixpkgs'in derleme ortamını hazırlayan setup-hook betikleri
    # `export "${cmd^^}"=...` gibi kabuk içi büyük harfe çevirme kullanıyor.
    # Büyük/küçük harf dönüşümünü LC_CTYPE belirler. Türkçe locale'de küçük "i"
    # harfinin büyüğü ASCII "I" değil, noktalı "İ"dir; yani "ranlib" -> "RANLİB"
    # olur ve "İ" geçerli bir kabuk değişkeni karakteri olmadığı için export
    # patlar. Bu, sandbox'lı derlemelerde değil, yalnızca kullanıcının ortamını
    # devralan nix-shell / nix develop gibi komutlarda görülür.
    #
    # Bu makinede birebir doğrulandı:
    #   LC_CTYPE=tr_TR.UTF-8  ->  ${v^^} = RANLİB   (hatalı)
    #   LC_CTYPE=C.UTF-8      ->  ${v^^} = RANLIB   (doğru)
    #
    # Çözüm: yalnızca LC_CTYPE'ı C.UTF-8 yap. UTF-8 olduğu için Türkçe karakterler
    # her yerde normal görüntülenip yazılmaya devam eder; arayüz ve konsol dili
    # (LANG / LC_MESSAGES) Türkçe kalır. Tek kaybedilen, komut satırı araçlarının
    # Türkçeye özgü büyük harf kuralı: `echo istanbul | tr a-z A-Z` artık
    # "İSTANBUL" değil "ISTANBUL" verir.
    #
    # Bu satırı kaldırmak istersen alternatif, sorunu komut bazında geçmektir:
    #   LC_CTYPE=C.UTF-8 nix-shell -p python3
    LC_CTYPE = "C.UTF-8";
  };

  i18n.supportedLocales = [
    "tr_TR.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
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
