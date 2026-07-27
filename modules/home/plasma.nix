# Declarative Plasma 6 configuration via plasma-manager.
#
# The NixOS wiki's KDE page notes: "With plasma-manager, it is possible to make
# Plasma configurations via nix by providing home-manager modules" and that
# "Plasma-Manager is a community project" — it is not part of nixpkgs, so its
# option set is versioned independently of NixOS. Keep this file conservative
# and let Plasma own anything not declared here.
#
# To capture settings made through System Settings and turn them into Nix:
#   nix run github:nix-community/plasma-manager
# (rc2nix dumps the current Plasma rc files as programs.plasma options.)
{ ... }:
{
  programs.plasma = {
    enable = true;

    # `overrideConfig = true` would wipe every setting not declared here on each
    # activation. Left off so the desktop stays hand-tunable.
    overrideConfig = false;

    ############################################################################
    # Look and feel
    ############################################################################
    workspace = {
      clickItemTo = "click"; # double-click to open, single-click to select
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";

      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };

      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/…";
    };

    ############################################################################
    # Panel — single bottom panel, 16:9 laptop panel at 1920x1080
    ############################################################################
    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          "org.kde.plasma.icontasks"
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    ############################################################################
    # Window manager
    ############################################################################
    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 1;
      };
    };

    ############################################################################
    # Shortcuts and hotkeys
    ############################################################################
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Konsole";
        key = "Meta+Return";
        command = "konsole";
      };
      "launch-dolphin" = {
        name = "Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
    };

    shortcuts = {
      "kwin"."Switch to Desktop 1" = "Meta+1";
      "kwin"."Switch to Desktop 2" = "Meta+2";
      "kwin"."Switch to Desktop 3" = "Meta+3";
      "kwin"."Switch to Desktop 4" = "Meta+4";
      "kwin"."Window Maximize" = "Meta+Up";
      "kwin"."Window Minimize" = "Meta+Down";
    };

    ############################################################################
    # Session lock
    ############################################################################
    kscreenlocker = {
      autoLock = true;
      timeout = 10; # minutes
      lockOnResume = true;
    };

    ############################################################################
    # Raw rc-file entries for anything without a dedicated option
    ############################################################################
    configFile = {
      # Baloo's file indexer is the biggest background I/O consumer on an
      # 8 GiB machine; Plasma search still works for applications.
      "baloofilerc"."Basic Settings"."Indexing-Enabled".value = false;

      # Turkish number/date formats already come from the system locale.
      "kdeglobals"."General"."BrowserApplication".value = "firefox.desktop";
    };
  };
}
