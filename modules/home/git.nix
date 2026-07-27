{ ... }:
{
  programs.git = {
    enable = true;

    # Home Manager'ın yeni arayüzü: userName / userEmail / extraConfig
    # seçenekleri `settings` altında birleştirildi.
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
}
