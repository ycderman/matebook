# Claude Desktop — Anthropic'in resmi .deb'inden repaketleme.
#
# AUR'daki claude-desktop paketinin (aur.archlinux.org/packages/claude-desktop)
# mantığının Nix çevirisi: .deb'in dosya yükünü (data.tar.xz) alıp
# autoPatchelfHook ile nixpkgs kütüphanelerine bağlıyor. Debian'a özgü
# install script'leri (apt repo kaydı, AppArmor istisnası) burada yok —
# NixOS'ta ilgisizler.
#
# Sürüm/hash güncellemesi: ./update.sh <yeni-sürüm> — `nix store prefetch-file`
# ile doğru hash'i otomatik hesaplayıp bu dosyayı yerinde düzenler.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libnotify,
  libcap_ng,
  libseccomp,
  libsecret,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  socat,
  systemd,
  util-linux,
  xdg-utils,
  # xorg.* paket seti kullanımdan kaldırıldı; X kütüphaneleri artık üst düzeyde.
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  qemu,
  virtiofsd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.24012.9";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256-MC5tII3YyOnlIGfaoo7zsRcaFhNYb9DhC+3GQiJbbuE=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];

  # namcap'in AUR PKGBUILD'inde "gerekmeyebilir" diye işaretlediği ama
  # dlopen/D-Bus/alt-süreç olarak gerçekten kullanılan kütüphaneler de dahil —
  # ELF başlığı analiziyle görünmezler, yine de runtime'da gerekiyorlar.
  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libnotify
    libcap_ng
    libseccomp
    libsecret
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    util-linux
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
  ];

  unpackPhase = ''
    runHook preUnpack
    # dpkg-deb -x tar'ın orijinal modları (chrome-sandbox'ın setuid biti
    # dahil) geri yüklemesini dener; build sandbox'ı setuid chmod'a izin
    # vermiyor. Nix mağazası zaten setuid bitini kalıcı olarak temizlediği
    # için burada da korumaya gerek yok — normal izinlerle aç.
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r usr/lib "$out/lib"
    cp -r usr/share "$out/share"

    # lintian override'ının NixOS'ta muhatabı yok.
    rm -rf "$out/share/lintian"

    mkdir -p "$out/bin"

    # Electron'un gömülü ANGLE'ı EGL/GLESv2'yi sabit, sürümlü soname'lerle
    # (libEGL.so.1, libGLESv2.so.2 — Debian'ın mesa paketleme kuralı) dlopen
    # ediyor; .deb'in kendi payload'ı ise sürümsüz isimlerle geliyor
    # (libEGL.so, libGLESv2.so). Dosya adı eşleşmediği için dlopen başarısız
    # oluyor, GPU süreci çöküp yazılım render'a düşüyor — autoPatchelfHook
    # bunu düzeltmez (DT_NEEDED değil, dlopen). Sürümlü isimlerle sembolik
    # bağlantı yeterli değil: Chromium sandboxlı alt süreçleri (gpu-process
    # dahil) LD_* ortam değişkenlerini temizliyor, bu da RUNPATH'in dlopen
    # için kendi sürecinde bile bazı alt süreç yollarında görünmemesine yol
    # açıyor — bu yüzden postFixup'ta wrapper'a ayrıca LD_LIBRARY_PATH
    # ekleniyor (RUNPATH'in atlandığı durumlar için yedek).
    ln -s libEGL.so "$out/lib/claude-desktop/libEGL.so.1"
    ln -s libGLESv2.so "$out/lib/claude-desktop/libGLESv2.so.2"

    runHook postInstall
  '';

  # wrapGAppsHook3, gappsWrapperArgs'ı (GSettings şema yolu, ikon teması,
  # XDG_DATA_DIRS) preFixup'ta dolduruyor; dontWrapGApps ile hook'un
  # kendiliğinden $out/bin altını sarmasını kapatıp, aynı argümanlarla
  # wrapper'ı postFixup'ta elle kuruyoruz (binary şimdiye kadar yalnızca
  # $out/lib altında, $out/bin'de henüz yok — çifte sarmalama riski yok).
  dontWrapGApps = true;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          socat
          qemu
          virtiofsd
        ]
      }
    )
  '';

  postFixup = ''
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "$out/lib/claude-desktop" \
      --add-flags "--disable-gpu"
  '';

  # --disable-gpu: bu makinede (Intel iHD/mesa, KWin/Wayland) GPU süreci EGL'i
  # başlatıyor ve Electron pencereyi "oluşturdum" sanıyor, ama gerçek Wayland
  # yüzeyi hiçbir zaman KWin'e ulaşmıyor — pencere görünmez, çökme/hata da
  # yok. --disable-gpu ile SwiftShader yazılım render'ına düşünce pencere
  # güvenilir şekilde beliriyor (elle doğrulandı: KWin script'iyle pencere
  # listesi --disable-gpu olmadan boş, varken "Claude" görünüyor). Kalıcı
  # düzgün çözüm iHD/DRM buffer format uyuşmazlığını bulmak olurdu; şimdilik
  # çalışan yapılandırma bu.

  # Chromium'un chrome-sandbox'ı setuid-root bekler; Nix mağazasına
  # kopyalanan dosyalar setuid bitini hiçbir zaman korumaz (mağaza
  # bütünlüğü için kasıtlı olarak temizlenir). NixOS varsayılan olarak
  # ayrıcalıksız user namespace'lere izin verdiğinden (AUR PKGBUILD'in
  # de belirttiği gibi bu zaten yalnızca hardened çekirdekler için bir
  # fallback), Chromium sandbox'ı bunlar üzerinden kuruyor — suid
  # yardımcısını zorlamaya çalışmıyoruz.

  # Elektron/Chromium önceden derlenmiş: strip gömülü kaynakları/V8
  # snapshot'ını bozabilir, kazanç da yok.
  dontStrip = true;

  meta = {
    description = "Desktop application for Claude.ai — Chat, Cowork, and Claude Code";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
