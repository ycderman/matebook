# Claude Desktop — ../../pkgs/claude-desktop içindeki .deb repaketlemesini
# pkgs.claude-desktop olarak açar (bkz. modules/home/packages.nix).
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      claude-desktop = final.callPackage ../../pkgs/claude-desktop { };
    })
  ];

  # Cowork'ün VM sandbox'ı (kod adı "yukonSilver"): virtiofsd ve OVMF
  # firmware'ini `/usr/bin/virtiofsd`, `/usr/share/OVMF/OVMF_CODE_4M.fd` gibi
  # sabit Debian/Ubuntu yollarında arıyor (app.asar'da strings ile doğrulandı).
  # NixOS'ta gerçek bir /usr yok; bu olmadan Cowork "not configured
  # (firmware/virtiofsd paths missing)" hatasıyla "unsupported" kalıyor.
  # AUR paketinin package() aşamasında yaptığı sembolik bağlantıların
  # NixOS karşılığı: gerçek dosyalar yerine Nix mağazasındaki karşılıklarına
  # işaret eden semboller.
  systemd.tmpfiles.rules =
    let
      ovmf = "${pkgs.OVMF.fd}/FV";
    in
    [
      "d /usr/share 0755 root root -"
      "d /usr/share/OVMF 0755 root root -"
      "d /usr/libexec 0755 root root -"
      "L+ /usr/bin/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
      "L+ /usr/libexec/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
      "L+ /usr/share/OVMF/OVMF_CODE.fd - - - - ${ovmf}/OVMF_CODE.fd"
      "L+ /usr/share/OVMF/OVMF_CODE_4M.fd - - - - ${ovmf}/OVMF_CODE.fd"
      "L+ /usr/share/OVMF/OVMF_VARS.fd - - - - ${ovmf}/OVMF_VARS.fd"
      "L+ /usr/share/OVMF/OVMF_VARS_4M.fd - - - - ${ovmf}/OVMF_VARS.fd"
    ];
}
