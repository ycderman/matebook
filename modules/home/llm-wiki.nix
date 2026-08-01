{ pkgs, ... }:
let
  wikiRoot = "/home/can/llm-wiki";
  stateDir = "/home/can/.local/state/llm-wiki";
in
{
  home.sessionVariables.LLM_WIKI_ROOT = wikiRoot;

  systemd.user.services.llm-wiki-update = {
    Unit = {
      Description = "Codex ve Claude Code ile LLM Wiki güncellemesi";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
      StartLimitIntervalSec = "6h";
      StartLimitBurst = 3;
    };

    Service = {
      Type = "oneshot";
      WorkingDirectory = wikiRoot;
      ExecStart = "${pkgs.bash}/bin/bash ${wikiRoot}/scripts/auto-update-wiki.sh";

      Environment = [
        "PATH=/home/can/.local/bin:/etc/profiles/per-user/can/bin:/run/current-system/sw/bin"
        "LLM_WIKI_ROOT=${wikiRoot}"
        "LLM_WIKI_STATE_DIR=${stateDir}"
        "CODEX_HOME=${stateDir}/codex-home"
        "CLAUDE_CONFIG_DIR=${stateDir}/claude-home"
        "LLM_WIKI_AUTOCOMMIT_MANUAL=0"
        "LC_ALL=C.UTF-8"
      ];

      Nice = 10;
      IOSchedulingClass = "idle";
      MemoryHigh = "2G";
      MemoryMax = "3G";
      TimeoutStartSec = "2h";
      Restart = "on-failure";
      RestartSec = "30m";
      UMask = "0077";
      StandardOutput = "null";
      StandardError = "journal";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        wikiRoot
        stateDir
      ];
      LockPersonality = true;
      RestrictSUIDSGID = true;
    };
  };

  systemd.user.timers.llm-wiki-update = {
    Unit.Description = "LLM Wiki'yi her gün güncelle";
    Timer = {
      OnCalendar = "daily";
      RandomizedDelaySec = "15m";
      AccuracySec = "1m";
      Persistent = true;
      Unit = "llm-wiki-update.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.tmpfiles.rules = [
    "d ${stateDir} 0700 - - -"
    "d ${stateDir}/runs 0700 - - -"
    "d ${stateDir}/codex-home 0700 - - -"
    "d ${stateDir}/claude-home 0700 - - -"
  ];
}
