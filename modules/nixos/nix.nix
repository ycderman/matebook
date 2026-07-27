# Nix daemon settings: flakes, garbage collection, store optimisation.
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

    # Emergency valve: collect garbage when the 512 GB NVMe runs low.
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
    '';

    # Make `nix shell nixpkgs#...` and `<nixpkgs>` resolve to the exact same
    # nixpkgs revision this system was built from.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.config.allowUnfree = true;

  # Small quality-of-life tools for a flake-based system.
  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nix-tree
    nvd
    nixfmt-rfc-style
  ];
}
