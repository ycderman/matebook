{ pkgs, ... }:
let
  wikiRoot = "/home/can/llm-wiki";
  stateDir = "/home/can/.local/state/llm-wiki";
  claudeSessionStart = pkgs.writeShellScript "claude-session-start" ''
    set -euo pipefail

    integration_file="${wikiRoot}/integration/second-brain.md"
    if [[ ! -r "$integration_file" ]]; then
      exit 0
    fi

    ${pkgs.jq}/bin/jq -n \
      --arg context "Personal second brain: read $integration_file before tasks that benefit from durable personal, project, computer, server, research, or decision context." \
      '{
        hookSpecificOutput: {
          hookEventName: "SessionStart",
          additionalContext: $context
        }
      }'
  '';
in
{
  home.sessionVariables.LLM_WIKI_ROOT = wikiRoot;

  home.file.".local/libexec/llm-wiki/claude-session-start" = {
    source = claudeSessionStart;
    executable = true;
  };

  systemd.user.services.llm-wiki-update = {
    Unit = {
      Description = "Codex ve Claude Code ile LLM Wiki güncellemesi";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
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
        "LC_ALL=C.UTF-8"
      ];

      Nice = 10;
      IOSchedulingClass = "idle";
      MemoryHigh = "2G";
      MemoryMax = "3G";
      TimeoutStartSec = "2h";
      UMask = "0077";

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
    Unit.Description = "LLM Wiki'yi 24 saatte bir güncelle";
    Timer = {
      OnBootSec = "15m";
      OnUnitActiveSec = "24h";
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
