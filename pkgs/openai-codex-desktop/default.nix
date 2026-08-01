{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  libarchive,
  libicns,
  asar,
  nodejs,
  node-gyp,
  python3,
  pkg-config,
  makeWrapper,
  electron_42,
  codex,
  libnotify,
  xdg-utils,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openai-codex-desktop";
  version = "26.721.41059";

  appArchive = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-arm64-${finalAttrs.version}.zip";
    hash = "sha256-4rRQVvPR+KuQ9/FiSb+1pA0J0PgJnxLKDY16j9+RCM4=";
  };

  betterSqlite3 = fetchurl {
    url = "https://registry.npmjs.org/better-sqlite3/-/better-sqlite3-12.9.0.tgz";
    hash = "sha256-rQ4pZQFAxJ0DNbHTVllqqBZvErdY9BiphEYTDjJ48lA=";
  };

  nodePty = fetchurl {
    url = "https://registry.npmjs.org/node-pty/-/node-pty-1.1.0.tgz";
    hash = "sha256-x1F/GQg93LBfJ2kEaA6ysRprXsq3eLjk5WhabWRbP2A=";
  };

  # AUR Linux uyumluluk katmanı, 2026-08-01 tarihli sabit commit.
  aurSource = fetchurl {
    url = "https://aur.archlinux.org/cgit/aur.git/snapshot/openai-codex-desktop.tar.gz?id=fd785a1095800d1204c4fa8b548c1f4e49be58d9";
    hash = "sha256-SklLFLOISEedVbVGzaCT0tV2SsOpDbn11Ny5QB+0YdY=";
  };

  # AUR native modülleri Electron 42.0.0 V8 API'sine karşı derliyor.
  electronHeaders = fetchzip {
    url = "https://artifacts.electronjs.org/headers/dist/v42.0.0/node-v42.0.0-headers.tar.gz";
    hash = "sha256-yiY502GOQIMaf9XRVD5PtMdPd9lngfyJpd54+v0+bKQ=";
  };

  nativeBuildInputs = [
    libarchive
    libicns
    asar
    nodejs
    node-gyp
    python3
    pkg-config
    makeWrapper
  ];

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    mkdir source aur icon
    bsdtar -xf "$aurSource" -C aur --strip-components 1
    bsdtar -xf "$appArchive" -C source

    appdir="$(find source -maxdepth 4 -type d -name '*.app' ! -path '*/__MACOSX/*' -print -quit)"
    test -n "$appdir"

    icon_icns="$(find "$appdir/Contents/Resources" -maxdepth 1 -type f -name '*.icns' ! -name '._*' -print -quit)"
    test -n "$icon_icns"
    icns2png -x -o icon "$icon_icns"

    asar extract "$appdir/Contents/Resources/app.asar" app-extracted
    if [[ -d "$appdir/Contents/Resources/app.asar.unpacked" ]]; then
      cp -a "$appdir/Contents/Resources/app.asar.unpacked" .
    fi

    rm -rf app-extracted/node_modules/sparkle-darwin
    find app-extracted -type f \( -name '*.dylib' -o -name 'sparkle.node' \) -delete

    # AUR yaması /usr/bin varsayımı yapıyor; NixOS'ta gerçek mağaza yolunu göm.
    chmod -R u+w aur
    substituteInPlace aur/patch-linux-notification-timeout.mjs \
      --replace-fail /usr/bin/notify-send ${libnotify}/bin/notify-send

    for patcher in \
      patch-linux-open-targets.mjs \
      patch-linux-opaque-bg.mjs \
      patch-linux-cli-history.mjs \
      patch-linux-notification-timeout.mjs \
      patch-linux-pet-lifecycle.mjs \
      patch-linux-pet-pointer-recovery.mjs; do
      node "aur/$patcher" app-extracted
    done

    # Uygulama tepsiyi yalnızca OpenAI'nin çatal Electron'undaki
    # Tray.whenReady/Tray.isReady varsa hazır sayıyor. nixpkgs Electron'unda bu
    # API yok, dolayısıyla Linux'ta tepsi kurulur kurulmaz yok ediliyor ve
    # pencere kapanınca uygulama çıkmak zorunda kalıyor. API yokken tepsiyi
    # hazır kabul et.
    main_bundle="$(echo app-extracted/.vite/build/main-*.js)"
    substituteInPlace "$main_bundle" \
      --replace-fail 'if(typeof t.whenReady!=`function`)return process.platform!==`linux`;' \
        'if(typeof t.whenReady!=`function`)return!0;' \
      --replace-fail 'return typeof t.isReady==`function`?t.isReady():process.platform!==`linux`' \
        'return typeof t.isReady==`function`?t.isReady():!0'

    rm -rf app-extracted/node_modules/better-sqlite3 app-extracted/node_modules/node-pty
    mkdir -p app-extracted/node_modules/better-sqlite3 app-extracted/node_modules/node-pty
    bsdtar -xf "$betterSqlite3" -C app-extracted/node_modules/better-sqlite3 --strip-components 1
    bsdtar -xf "$nodePty" -C app-extracted/node_modules/node-pty --strip-components 1

    sqlite_src=app-extracted/node_modules/better-sqlite3/src
    substituteInPlace "$sqlite_src/better_sqlite3.cpp" \
      --replace-fail 'v8::External::New(isolate, addon)' \
        'v8::External::New(isolate, addon, v8::kExternalPointerTypeTagDefault)'
    substituteInPlace "$sqlite_src/util/macros.cpp" \
      --replace-fail 'v8::External>()->Value()' \
        'v8::External>()->Value(v8::kExternalPointerTypeTagDefault)'
    sed -i '/SetNativeDataProperty/,/);/{s/\t\t0,/\t\tnullptr,/}' "$sqlite_src/util/helpers.cpp"

    export npm_config_runtime=electron
    export npm_config_target="42.0.0"
    export npm_config_nodedir="$electronHeaders"
    export npm_config_build_from_source=true

    for module in better-sqlite3 node-pty; do
      pushd "app-extracted/node_modules/$module"
      # nixpkgs node-gyp sarmalayıcısı npm_config_nodedir'i Node 24'e zorlar;
      # sarmalayıcıyı atlayıp Electron başlıklarını doğrudan kullan.
      node ${node-gyp}/lib/node_modules/node-gyp/bin/node-gyp.js \
        rebuild --release --nodedir="$electronHeaders"
      popd
    done

    for prebuild_root in app-extracted app.asar.unpacked; do
      [[ -d "$prebuild_root" ]] || continue
      find "$prebuild_root" -path '*/prebuilds/*' -type f -name '*.node' \
        ! \( -path '*/linux-x64/*' -o -path '*/HID-linux-x64/*' -o -path '*/HID_hidraw-linux-x64/*' \) \
        -delete
      find "$prebuild_root" -path '*/prebuilds/*' -type f -name '*musl*.node' -delete
    done

    asar pack app-extracted app.asar --unpack '{*.node,*.so}'

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    appout="$out/lib/openai-codex-desktop"
    mkdir -p "$appout/resources" "$out/bin" "$out/share/applications" \
      "$out/share/icons/hicolor/512x512/apps"

    install -m644 app.asar "$appout/resources/app.asar"
    if [[ -d app.asar.unpacked ]]; then
      cp -a app.asar.unpacked "$appout/resources/"
    fi
    if [[ -d app-extracted/webview ]]; then
      mkdir -p "$appout/content"
      cp -a app-extracted/webview "$appout/content/"
    fi

    install -m644 aur/kwin-codex-pet-keep-above.js "$appout/kwin-codex-pet-keep-above.js"
    ln -s ${electron_42}/bin/electron "$appout/codex"

    install -m755 aur/codex-desktop.sh "$appout/codex-desktop.sh"
    substituteInPlace "$appout/codex-desktop.sh" \
      --replace-fail 'appdir="/usr/lib/openai-codex-desktop"' "appdir=\"$appout\"" \
      --replace-fail /usr/bin/qdbus6 ${qt6.qttools}/bin/qdbus6

    # Pencere kapatıldığında uygulama sistem tepsisinde çalışmaya devam etsin.
    # Tepsi ikonu hazır olmazsa Electron yine de çıkar, arkada asılı kalmaz.
    makeWrapper "$appout/codex-desktop.sh" "$out/bin/codex-desktop" \
      --set-default CODEX_DESKTOP_QUIT_ON_LAST_WINDOW 0 \
      --prefix PATH : ${
        lib.makeBinPath [
          codex
          python3
          libnotify
          xdg-utils
          qt6.qttools
        ]
      }

    install -m644 aur/Codex.desktop "$out/share/applications/Codex.desktop"
    icon_png="$(find icon -maxdepth 1 -type f -name '*512x512*.png' -print -quit)"
    if [[ -z "$icon_png" ]]; then
      icon_png="$(find icon -maxdepth 1 -type f -name '*.png' -print | sort -V | tail -n1)"
    fi
    test -n "$icon_png"
    install -m644 "$icon_png" "$out/share/icons/hicolor/512x512/apps/openai-codex-desktop.png"

    # Linux tepsi ikonu. macOS arşivi PNG ikon içermiyor ve Electron uygulamayı
    # argüman olarak aldığı için `app.isPackaged` false kalıyor; bu yolda ikon
    # `<repoRoot>/electron/src/icons/icon.png` olarak aranıyor ve repoRoot
    # `resources` dizinine denk geliyor. Dosya yoksa tepsi kurulumu hata verir
    # ve uygulama son pencere kapanınca çıkar.
    install -Dm644 "$icon_png" "$appout/resources/electron/src/icons/icon.png"

    install -Dm644 aur/LICENSE "$out/share/licenses/openai-codex-desktop/LICENSE"

    runHook postInstall
  '';

  dontStrip = true;

  meta = {
    description = "OpenAI Codex desktop app, repackaged for Linux";
    homepage = "https://developers.openai.com/codex/app/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex-desktop";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
