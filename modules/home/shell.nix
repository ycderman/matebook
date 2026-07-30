# Etkileşimli kabuk — bash (modules/nixos/users.nix'teki giriş kabuğuyla aynı).
{ ... }:
let
  # inputs.cinevara özel bir GitHub deposu; nix'in onu fetch edebilmesi için
  # GitHub kimliği gerekiyor. Token'ı gh'nin keyring'inden alıp nix'e geçiyoruz —
  # depoya/dosyaya sabit token yazılmıyor. Tek önkoşul: `gh auth login`
  # yapılmış olması. Komut çalıştığı anda genişler (alias gövdesi kullanım
  # anında yeniden ayrıştırılır), sudo'ya girmeden önce `can` olarak çözülür.
  ghToken = ''--option access-tokens "github.com=$(gh auth token)"'';
in
{
  programs.bash = {
    enable = true;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    historySize = 10000;
    historyFileSize = 20000;
    shellAliases = {
      ll = "eza -l --group-directories-first";
      la = "eza -la --group-directories-first";
      lt = "eza --tree --level=2";
      cat = "bat --paging=never";
      grep = "rg";
      df = "df -h";
      du = "ncdu";
      # Flake akışı — yapılandırma ~/nixos-config içinde (tek konum; /etc/nixos
      # buna sembolik bağlantı, bkz. README Adım 10)
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#matebook ${ghToken}";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config#matebook ${ghToken}";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos-config#matebook ${ghToken}";
      update = "nix flake update --flake ~/nixos-config ${ghToken}";
      # Homeserver
      hs = "ssh can@192.168.1.3";
    };
    initExtra = ''
      export PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };
  home.sessionVariables = {
    # EDITOR/VISUAL burada değil: sistem geneli tek yerde tanımlı
    # (modules/nixos/packages.nix -> environment.variables), oturuma oradan geliyor.
    # İhtiyaç duyan araç setleri için Wayland'e özgü çizim.
    NIXOS_OZONE_WL = "1";
  };
}
