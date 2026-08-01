{
  lib,
  stdenvNoCC,
  python3,
  gtk4,
  libadwaita,
  webkitgtk_6_0,
  libsoup_3,
  glib-networking,
  gobject-introspection,
  wrapGAppsHook4,
  makeDesktopItem,
  copyDesktopItems,
  gallery-dl,
  ffmpeg,
  gst_all_1,
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.pygobject3 ]);

  # WebKitGTK medya oynatma için GStreamer eklentilerini çalışma zamanında arar;
  # H.264 (Instagram video) gst-libav'da.
  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-libav
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "instagram-desktop";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
    copyDesktopItems
  ];

  buildInputs = [
    gtk4
    libadwaita
    webkitgtk_6_0
    libsoup_3
    glib-networking
    pythonEnv
  ];

  # Sarmalayıcıyı elle kuruyoruz: gappsWrapperArgs + PATH + GStreamer yolu.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 src/instagram_desktop.py \
      "$out/share/instagram-desktop/instagram_desktop.py"
    install -Dm644 data/instagram-desktop.svg \
      "$out/share/icons/hicolor/scalable/apps/instagram-desktop.svg"

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper ${pythonEnv}/bin/python3 "$out/bin/instagram-desktop" \
      --add-flags "$out/share/instagram-desktop/instagram_desktop.py" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ gallery-dl ffmpeg ]} \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "instagram-desktop";
      desktopName = "Instagram";
      genericName = "Instagram client";
      comment = "Instagram istemcisi ve medya indirici";
      exec = "instagram-desktop %u";
      icon = "instagram-desktop";
      terminal = false;
      categories = [
        "Network"
        "Graphics"
      ];
      keywords = [
        "instagram"
        "reels"
        "download"
      ];
      startupWMClass = "io.github.can.InstagramDesktop";
    })
  ];

  meta = {
    description = "Instagram desktop client with a gallery-dl based downloader";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "instagram-desktop";
  };
})
