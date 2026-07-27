# Home Manager wired in as a NixOS module, with plasma-manager available to
# every user configuration.
# https://wiki.nixos.org/wiki/Home_Manager
{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    # Use the system's nixpkgs (already pinned by the flake) instead of a
    # second, independently evaluated one.
    useGlobalPkgs = true;

    # Install user packages into the user profile.
    useUserPackages = true;

    # Rename pre-existing dotfiles instead of failing the activation.
    backupFileExtension = "hm-bak";

    # Flake inputs reach the home modules too.
    extraSpecialArgs = { inherit inputs; };

    # plasma-manager is a Home Manager module, not a NixOS one.
    # https://wiki.nixos.org/wiki/KDE
    sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ];

    users.can = import ../home;
  };
}
