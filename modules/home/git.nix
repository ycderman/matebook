{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ycderman";
        email = "y.canderman@proton.me";
      };
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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nano";
      prompt = "enabled";
    };
  };
}
