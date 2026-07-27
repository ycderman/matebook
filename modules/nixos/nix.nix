# Nix daemon ayarları: flake'ler, çöp toplama, store optimizasyonu.
{
  inputs,
  pkgs,
  ...
}:
{
  nix = {
    # https://wiki.nixos.org/wiki/Flakes
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "root"
        "can"
      ];

      warn-dirty = false;
    };

    # https://wiki.nixos.org/wiki/Storage_optimization
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    optimise = {
      automatic = true;
      dates = [ "03:45" ];
    };

    # Acil durum valfi: 512 GB'lık NVMe dolmaya başlarsa kendiliğinden temizlik.
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
    '';

    # `nix shell nixpkgs#...` ve `<nixpkgs>` ifadelerinin, sistemin derlendiği
    # nixpkgs sürümünün tam olarak aynısına çözülmesini sağlar.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config.allowUnfree = true;

  # Flake tabanlı bir sistemi rahat kullandıran küçük araçlar.
  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nix-tree
    nvd
    nixfmt # eskiden nixfmt-rfc-style; artık ikisi aynı paket
  ];
}
