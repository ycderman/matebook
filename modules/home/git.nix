{ ... }:
{
  programs.git = {
    enable = true;

    userName = "ycderman";
    userEmail = "y.canderman@proton.me";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nano";
      diff.algorithm = "histogram";
    };

    ignores = [
      "result"
      "result-*"
      ".direnv/"
    ];
  };
}
