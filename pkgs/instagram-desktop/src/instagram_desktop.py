#!/usr/bin/env python3
"""Instagram desktop client: persistent WebKit session + gallery-dl downloader."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

import gi

gi.require_version("Adw", "1")
gi.require_version("Gtk", "4.0")
gi.require_version("WebKit", "6.0")
gi.require_version("Soup", "3.0")

from gi.repository import Adw, Gdk, Gio, GLib, Gtk, WebKit  # noqa: E402

APP_ID = "io.github.can.InstagramDesktop"
HOME_URL = "https://www.instagram.com/"
MESSAGE_HANDLER = "igdl"

# gallery-dl, Chrome dışı bir User-Agent gördüğünde Instagram'ın düşük kaliteli
# video varyantları döndürdüğü konusunda uyarıyor; istemci de indirici de aynı
# masaüstü Chrome kimliğini kullanıyor.
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/137.0.0.0 Safari/537.36"
)

DATA_DIR = Path(GLib.get_user_data_dir()) / "instagram-desktop"
CACHE_DIR = Path(GLib.get_user_cache_dir()) / "instagram-desktop"
COOKIE_DB = DATA_DIR / "cookies.sqlite"
COOKIE_EXPORT = DATA_DIR / "cookies-export.txt"
LOG_FILE = DATA_DIR / "gallery-dl.log"
LOG_LIMIT = 1 << 20

# İndirilebilir Instagram yolları; akışın kendisinin extractor'ı yok.
DOWNLOADABLE_PREFIXES = ("/p/", "/reel/", "/reels/", "/tv/", "/stories/", "/s/")
NON_PROFILE_PATHS = {"", "/", "/explore/", "/direct/", "/accounts/", "/reels/audio/"}

# Her gönderinin kendi "..." menüsüne bir indirme satırı ekler. Satır, menüdeki
# ilk satırın kopyası olduğu için Instagram'ın kendi stilini alır.
USER_SCRIPT = """
(function () {
  if (window.__igdl) { return; }
  window.__igdl = true;

  var LABEL = "İndir";
  var LINKS = 'a[href*="/p/"], a[href*="/reel/"], a[href*="/tv/"]';
  var context = null;

  function permalink(root) {
    var link = root.querySelector ? root.querySelector(LINKS) : null;
    return link ? link.href : null;
  }

  function targetUrl() {
    var node = context;
    while (node && node !== document.body) {
      if (node.tagName === "ARTICLE") {
        var inArticle = permalink(node);
        if (inArticle) { return inArticle; }
      }
      node = node.parentElement;
    }
    // Reels ve hikâye görünümünde <article> yok: tıklanan öğenin yakın
    // atalarına bak, orada da bulunamazsa adres çubuğundaki içeriğe düş.
    node = context;
    for (var depth = 0; node && node !== document.body && depth < 8; depth++) {
      var nearby = permalink(node);
      if (nearby) { return nearby; }
      node = node.parentElement;
    }
    return location.href;
  }

  // Yalnızca metin düğümünü değiştir: satırın iç sarmalayıcıları (dolayısıyla
  // hizası ve boşlukları) Instagram'ın kendi satırlarıyla aynı kalsın.
  function setLabel(entry, label) {
    var walker = document.createTreeWalker(entry, NodeFilter.SHOW_TEXT);
    var nodes = [];
    while (walker.nextNode()) {
      if (walker.currentNode.nodeValue.trim()) { nodes.push(walker.currentNode); }
    }
    if (!nodes.length) {
      entry.textContent = label;
      return;
    }
    nodes[0].nodeValue = label;
    nodes.slice(1).forEach(function (node) { node.nodeValue = ""; });
  }

  function isMenu(dialog) {
    if (dialog.querySelector("article, video, img, canvas")) { return false; }
    if (dialog.textContent.length > 400) { return false; }
    return dialog.querySelectorAll('[role="button"], button').length >= 2;
  }

  function inject(dialog, url) {
    if (!dialog || dialog.querySelector("[data-igdl]")) { return; }
    if (!isMenu(dialog)) { return; }

    var items = Array.prototype.filter.call(
      dialog.querySelectorAll('[role="button"], button'),
      function (item) { return item.textContent.trim().length > 0; }
    );
    var first = items[0];
    if (!first || !first.parentElement) { return; }

    var entry = first.cloneNode(true);
    entry.setAttribute("data-igdl", "1");
    setLabel(entry, LABEL);
    entry.addEventListener("click", function (event) {
      event.preventDefault();
      event.stopPropagation();
      window.webkit.messageHandlers.igdl.postMessage(url);
      document.dispatchEvent(
        new KeyboardEvent("keydown", { key: "Escape", bubbles: true })
      );
    }, true);
    first.parentElement.insertBefore(entry, first);
  }

  document.addEventListener("click", function (event) {
    context = event.target;
  }, true);

  function schedule(dialog) {
    // Menü içeriğini React, diyalog eklendikten sonra dolduruyor.
    var url = targetUrl();
    [0, 120, 300, 600].forEach(function (delay) {
      setTimeout(function () {
        if (document.contains(dialog)) { inject(dialog, url); }
      }, delay);
    });
  }

  new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) {
      Array.prototype.forEach.call(mutation.addedNodes, function (node) {
        if (node.nodeType !== 1) { return; }
        if (node.matches && node.matches('div[role="dialog"]')) {
          schedule(node);
        }
        if (node.querySelectorAll) {
          Array.prototype.forEach.call(
            node.querySelectorAll('div[role="dialog"]'), schedule
          );
        }
      });
    });
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
"""


def download_dir() -> Path:
    override = os.environ.get("INSTAGRAM_DESKTOP_DOWNLOAD_DIR")
    if override:
        return Path(override).expanduser()
    base = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOWNLOAD)
    return Path(base or GLib.get_home_dir()) / "Instagram"


def is_downloadable(uri: str) -> bool:
    if not uri.startswith("http"):
        return False
    parts = GLib.Uri.parse(uri, GLib.UriFlags.NONE)
    host = (parts.get_host() or "").removeprefix("www.")
    if host != "instagram.com":
        return False
    path = parts.get_path() or "/"
    if path.startswith(DOWNLOADABLE_PREFIXES):
        return True
    if path in NON_PROFILE_PATHS or path.startswith(("/explore", "/direct", "/accounts")):
        return False
    # /<username>/ ve sekmeleri (/reels/, /tagged/) profil extractor'ına gider.
    return len(path.strip("/").split("/")) <= 2


def write_cookie_file(cookies) -> Path | None:
    """Write a Netscape cookie jar readable by gallery-dl, owner-only."""
    lines = ["# Netscape HTTP Cookie File", "# generated by instagram-desktop"]
    for cookie in cookies:
        domain = cookie.get_domain()
        expires = cookie.get_expires()
        lines.append(
            "\t".join(
                [
                    domain,
                    "TRUE" if domain.startswith(".") else "FALSE",
                    cookie.get_path() or "/",
                    "TRUE" if cookie.get_secure() else "FALSE",
                    str(expires.to_unix() if expires else 0),
                    cookie.get_name(),
                    cookie.get_value(),
                ]
            )
        )
    if len(lines) == 2:
        return None
    COOKIE_EXPORT.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(COOKIE_EXPORT, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as handle:
        handle.write("\n".join(lines) + "\n")
    return COOKIE_EXPORT


class InstagramWindow(Adw.ApplicationWindow):
    def __init__(self, app: Adw.Application):
        super().__init__(
            application=app,
            title="Instagram",
            default_width=1150,
            default_height=860,
        )
        self.active_jobs = 0

        for directory in (DATA_DIR, CACHE_DIR):
            directory.mkdir(parents=True, exist_ok=True)

        self.session = WebKit.NetworkSession.new(
            str(DATA_DIR / "webkit"), str(CACHE_DIR / "webkit")
        )
        cookies = self.session.get_cookie_manager()
        cookies.set_accept_policy(WebKit.CookieAcceptPolicy.ALWAYS)
        cookies.set_persistent_storage(
            str(COOKIE_DB), WebKit.CookiePersistentStorage.SQLITE
        )

        content = WebKit.UserContentManager()
        content.register_script_message_handler(MESSAGE_HANDLER, None)
        content.connect(
            f"script-message-received::{MESSAGE_HANDLER}", self.on_script_message
        )
        content.add_script(
            WebKit.UserScript.new(
                USER_SCRIPT,
                WebKit.UserContentInjectedFrames.TOP_FRAME,
                WebKit.UserScriptInjectionTime.END,
                None,
                None,
            )
        )

        self.webview = WebKit.WebView(
            network_session=self.session,
            user_content_manager=content,
            vexpand=True,
        )
        settings = self.webview.get_settings()
        settings.set_user_agent(USER_AGENT)
        settings.set_enable_developer_extras(True)
        settings.set_enable_smooth_scrolling(True)
        settings.set_media_playback_requires_user_gesture(False)

        self.build_ui()
        self.install_actions()

        # Sinyaller yalnızca arayüz kurulduktan sonra bağlanır; load_uri anında
        # notify::uri tetikliyor.
        self.webview.connect("notify::uri", self.on_uri_changed)
        self.webview.connect("notify::estimated-load-progress", self.on_progress)
        self.webview.connect("create", self.on_create)
        self.webview.load_uri(HOME_URL)

    # ---------------------------------------------------------------- UI

    def build_ui(self) -> None:
        self.window_title = Adw.WindowTitle(title="Instagram", subtitle=HOME_URL)

        header = Adw.HeaderBar(title_widget=self.window_title)

        nav = Gtk.Box(css_classes=["linked"])
        self.back_button = Gtk.Button(
            icon_name="go-previous-symbolic", tooltip_text="Geri", sensitive=False
        )
        self.back_button.connect("clicked", lambda *_: self.webview.go_back())
        self.forward_button = Gtk.Button(
            icon_name="go-next-symbolic", tooltip_text="İleri", sensitive=False
        )
        self.forward_button.connect("clicked", lambda *_: self.webview.go_forward())
        nav.append(self.back_button)
        nav.append(self.forward_button)
        header.pack_start(nav)

        reload_button = Gtk.Button(
            icon_name="view-refresh-symbolic", tooltip_text="Yenile (Ctrl+R)"
        )
        reload_button.connect("clicked", lambda *_: self.webview.reload())
        header.pack_start(reload_button)

        home_button = Gtk.Button(icon_name="go-home-symbolic", tooltip_text="Ana sayfa")
        home_button.connect("clicked", lambda *_: self.webview.load_uri(HOME_URL))
        header.pack_start(home_button)

        menu = Gio.Menu()
        menu.append("Bağlantıdan indir…", "win.download-link")
        menu.append("Açık içeriği indir", "win.download-current")
        menu.append("İndirme klasörünü aç", "win.open-folder")
        menu.append("Oturumu kapat ve verileri sil", "win.clear-session")
        header.pack_end(
            Gtk.MenuButton(
                icon_name="open-menu-symbolic", menu_model=menu, tooltip_text="Menü"
            )
        )

        self.progress = Gtk.ProgressBar(
            visible=False, css_classes=["osd"], valign=Gtk.Align.START
        )

        overlay = Gtk.Overlay(child=self.webview)
        overlay.add_overlay(self.progress)

        toolbar = Adw.ToolbarView(content=overlay)
        toolbar.add_top_bar(header)

        self.toasts = Adw.ToastOverlay(child=toolbar)
        self.set_content(self.toasts)

    def install_actions(self) -> None:
        actions = {
            "download-current": lambda *_: self.start_download(self.webview.get_uri()),
            "download-link": lambda *_: self.ask_for_link(),
            "open-folder": lambda *_: self.open_download_dir(),
            "clear-session": lambda *_: self.confirm_clear_session(),
        }
        group = Gio.SimpleActionGroup()
        for name, callback in actions.items():
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", callback)
            group.add_action(action)
        self.insert_action_group("win", group)

        app = self.get_application()
        app.set_accels_for_action("win.download-current", ["<Control>d"])
        app.set_accels_for_action("win.download-link", ["<Control>l"])

    # ----------------------------------------------------------- webview

    def on_uri_changed(self, *_args) -> None:
        uri = self.webview.get_uri() or ""
        self.window_title.set_subtitle(uri)
        self.back_button.set_sensitive(self.webview.can_go_back())
        self.forward_button.set_sensitive(self.webview.can_go_forward())

    def on_progress(self, *_args) -> None:
        value = self.webview.get_estimated_load_progress()
        self.progress.set_fraction(value)
        self.progress.set_visible(0.0 < value < 1.0)

    def on_create(self, webview, navigation_action):
        uri = navigation_action.get_request().get_uri()
        if "instagram.com" in (GLib.Uri.parse(uri, GLib.UriFlags.NONE).get_host() or ""):
            webview.load_uri(uri)
        else:
            Gtk.UriLauncher(uri=uri).launch(self, None, None)
        return None

    def on_script_message(self, _manager, value) -> None:
        self.start_download(value.to_string())

    # ---------------------------------------------------------- download

    def start_download(self, uri: str | None) -> None:
        if not uri or not is_downloadable(uri):
            self.notify_user("Bu içerik indirilemez.")
            return
        if shutil.which("gallery-dl") is None:
            self.notify_user("gallery-dl bulunamadı.")
            return

        def on_cookies(manager, result):
            try:
                cookies = manager.get_cookies_finish(result)
            except GLib.Error as error:
                self.notify_user(f"Çerezler okunamadı: {error.message}")
                return
            jar = write_cookie_file(cookies)
            if jar is None:
                self.notify_user("Oturum çerezi yok. Önce Instagram'a giriş yap.")
                return
            self.spawn_gallery_dl(uri, jar)

        self.session.get_cookie_manager().get_cookies(HOME_URL, None, on_cookies)

    def spawn_gallery_dl(self, uri: str, jar: Path) -> None:
        target = download_dir()
        target.mkdir(parents=True, exist_ok=True)
        command = [
            "gallery-dl",
            "--cookies",
            str(jar),
            "--user-agent",
            USER_AGENT,
            "--destination",
            str(target),
            # Video, DASH manifestinden alınır: yt-dlp en yüksek çözünürlüklü
            # temsili seçer, ffmpeg sesle birleştirir. Görsellerde gallery-dl
            # zaten en büyük candidate'ı indiriyor.
            "--option",
            "extractor.instagram.videos=true",
            uri,
        ]
        self.active_jobs += 1
        self.notify_user("İndiriliyor…")
        threading.Thread(
            target=self.run_gallery_dl, args=(command, jar, uri), daemon=True
        ).start()

    def run_gallery_dl(self, command: list[str], jar: Path, uri: str) -> None:
        code = -1
        try:
            if LOG_FILE.exists() and LOG_FILE.stat().st_size > LOG_LIMIT:
                LOG_FILE.unlink()
            with LOG_FILE.open("a") as log:
                log.write(f"\n=== {time.strftime('%F %T')} {uri}\n")
                log.flush()
                code = subprocess.call(command, stdout=log, stderr=subprocess.STDOUT)
        except OSError as error:
            with LOG_FILE.open("a") as log:
                log.write(f"error: {error}\n")
        finally:
            jar.unlink(missing_ok=True)
        GLib.idle_add(self.finish_download, code)

    def finish_download(self, code: int) -> None:
        self.active_jobs = max(0, self.active_jobs - 1)
        self.notify_user("İndirildi." if code == 0 else "İndirme başarısız oldu.")

    # ------------------------------------------------------------ dialogs

    def ask_for_link(self) -> None:
        entry = Gtk.Entry(
            placeholder_text="https://www.instagram.com/p/…",
            activates_default=True,
            hexpand=True,
        )
        dialog = Adw.AlertDialog(
            heading="Bağlantıdan indir",
            body="Gönderi, reel, hikâye veya profil bağlantısı.",
            extra_child=entry,
        )
        dialog.add_response("cancel", "Vazgeç")
        dialog.add_response("download", "İndir")
        dialog.set_response_appearance("download", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("download")
        dialog.set_close_response("cancel")

        def on_response(_dialog, response):
            if response == "download":
                self.start_download(entry.get_text().strip())

        dialog.connect("response", on_response)

        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.read_text_async(None, lambda c, r: self.prefill(entry, c, r))
        dialog.present(self)

    def prefill(self, entry: Gtk.Entry, clipboard, result) -> None:
        try:
            text = clipboard.read_text_finish(result) or ""
        except GLib.Error:
            text = ""
        if is_downloadable(text.strip()):
            entry.set_text(text.strip())
            entry.select_region(0, -1)

    def confirm_clear_session(self) -> None:
        dialog = Adw.AlertDialog(
            heading="Oturumu kapat",
            body="Çerezler, önbellek ve yerel site verileri silinecek. "
            "Tekrar giriş yapman gerekir.",
        )
        dialog.add_response("cancel", "Vazgeç")
        dialog.add_response("clear", "Sil")
        dialog.set_response_appearance("clear", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_close_response("cancel")
        dialog.connect(
            "response",
            lambda _d, response: self.clear_session() if response == "clear" else None,
        )
        dialog.present(self)

    def clear_session(self) -> None:
        manager = self.session.get_website_data_manager()
        manager.clear(WebKit.WebsiteDataTypes.ALL, 0, None, self.on_cleared)

    def on_cleared(self, manager, result) -> None:
        try:
            manager.clear_finish(result)
        except GLib.Error as error:
            self.notify_user(f"Silinemedi: {error.message}")
            return
        COOKIE_EXPORT.unlink(missing_ok=True)
        self.notify_user("Oturum verileri silindi.")
        self.webview.load_uri(HOME_URL)

    def open_download_dir(self) -> None:
        target = download_dir()
        target.mkdir(parents=True, exist_ok=True)
        Gtk.FileLauncher(file=Gio.File.new_for_path(str(target))).launch(self, None, None)

    def notify_user(self, message: str) -> None:
        self.toasts.add_toast(Adw.Toast(title=message, timeout=3))


class InstagramApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id=APP_ID,
            flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
        )

    def do_command_line(self, command_line):
        arguments = command_line.get_arguments()[1:]
        self.activate()
        window = self.props.active_window
        if arguments and window:
            window.start_download(arguments[0])
        return 0

    def do_activate(self):
        window = self.props.active_window or InstagramWindow(self)
        window.present()


def main() -> int:
    return InstagramApp().run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
