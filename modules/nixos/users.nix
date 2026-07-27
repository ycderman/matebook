# User accounts.
{ pkgs, ... }:
{
  users.users.can = {
    isNormalUser = true;
    description = "Can Derman";
    shell = pkgs.bash;

    extraGroups = [
      "wheel" # sudo
      "networkmanager" # Wi-Fi from the Plasma applet
      "video" # backlight control (intel_backlight)
      "audio"
      "input"
    ];

    # First-boot password only. Change it right after the first login with
    # `passwd`, or replace this with `hashedPasswordFile` and set
    # users.mutableUsers = false for a fully declarative account.
    initialPassword = "nixos";
  };

  # sudo for the wheel group, with a password.
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # No root login.
  users.users.root.hashedPassword = "!";
}
