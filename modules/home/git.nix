{ ... }:
{
  programs.git = {
    enable = true;

    userName = "Can Derman";
    userEmail = "y.canderman@proton.me";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "vim";
      diff.algorithm = "histogram";
    };

    ignores = [
      "result"
      "result-*"
      ".direnv/"
    ];
  };
}
