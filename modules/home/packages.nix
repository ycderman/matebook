# User-level packages. System tooling lives in modules/nixos/packages.nix.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminal
    btop
    fastfetch
    ripgrep
    fd
    eza
    bat
    jq
    tree
    ncdu

    # Media (hardware accelerated through iHD / VA-API)
    mpv
    ffmpeg

    # Browser (referenced by kdeglobals BrowserApplication in plasma.nix)
    firefox

    # okular / gwenview / spectacle / kate already come with the Plasma 6
    # module's default package set — see environment.plasma6.excludePackages
    # in modules/nixos/desktop.nix for trimming it.
  ];
}
