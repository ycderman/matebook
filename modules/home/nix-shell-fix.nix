# Türkçe locale + nixpkgs derleme ortamı çakışmasının hedefe yönelik çözümü.
#
# SORUN
#   nix-shell -p python3
#   bash: export: `RANLİB=ranlib': not a valid identifier
#
#   nixpkgs'in derleme ortamını kuran setup-hook betikleri, değişken adlarını
#   `export "${cmd^^}"=...` gibi kabuk içi büyük harfe çevirmeyle üretiyor.
#   Bu dönüşümü LC_CTYPE belirler ve Türkçede küçük "i" harfinin büyüğü ASCII
#   "I" değil, noktalı "İ"dir. Sonuç: "ranlib" -> "RANLİB", ve "İ" geçerli bir
#   kabuk değişkeni karakteri olmadığı için export patlar.
#
#   Sandbox'lı derlemelerde görülmez (orada locale ayarlı değil); yalnızca
#   senin ortamını devralan nix-shell / nix develop gibi komutlar etkilenir.
#
#   Bu makinede birebir doğrulandı:
#     LC_CTYPE=tr_TR.UTF-8  ->  ${v^^} = RANLİB   (hata)
#     LC_CTYPE=C.UTF-8      ->  ${v^^} = RANLIB   (düzgün)
#
# ÇÖZÜM
#   Sistem diline dokunulmuyor — LANG ve bütün LC_* değişkenleri tr_TR.UTF-8
#   kalıyor. Bunun yerine yalnızca ilgili nix komutları, kendi alt süreçlerine
#   LC_CTYPE=C.UTF-8 verecek şekilde sarmalanıyor. Yani düzeltme tam olarak
#   derleme ortamının içinde kalıyor, senin kabuğunu etkilemiyor.
#
#   Sarmalayıcılar kullanıcı profiline (/etc/profiles/per-user/can/bin) kurulur
#   ve PATH'te sistem profilinden (/run/current-system/sw/bin) önce geldiği için
#   gerçek ikilileri gölgeler. Ad çakışması ya da öncelik ayarı gerekmez.
#
#   Kaldırmak istersen: bu dosyayı modules/home/default.nix içindeki imports
#   listesinden çıkar; o zaman komut bazında elle yapman gerekir:
#     LC_CTYPE=C.UTF-8 nix-shell -p python3
{ pkgs, ... }:
let
  # Sistemdeki gerçek nix paketi (useGlobalPkgs sayesinde nix.package ile aynı
  # store yolu — fazladan bir kopya oluşmuyor).
  nix = pkgs.nix;

  # nix-shell: stdenv kurulumunu doğrudan çalıştırdığı için asıl sorunlu komut.
  nix-shell-wrapper = pkgs.writeShellScriptBin "nix-shell" ''
    export LC_CTYPE=C.UTF-8
    exec ${nix}/bin/nix-shell "$@"
  '';

  # nix: aynı stdenv kurulumunu yapan alt komutlar için. Yalnızca bu alt
  # komutlarda değişken ayarlanıyor; `nix run`, `nix build`, `nix flake` vb.
  # tamamen dokunulmadan gerçek ikiliye geçiyor.
  nix-wrapper = pkgs.writeShellScriptBin "nix" ''
    case "''${1-}" in
      develop|print-dev-env)
        export LC_CTYPE=C.UTF-8
        ;;
    esac
    exec ${nix}/bin/nix "$@"
  '';
in
{
  home.packages = [
    nix-shell-wrapper
    nix-wrapper
  ];
}
