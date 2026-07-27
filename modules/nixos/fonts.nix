# Yazı tipleri — tam Türkçe karakter kapsamı ve bir kodlama fontu.
{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji # eski adı noto-fonts-emoji
      liberation_ttf
      dejavu_fonts
      nerd-fonts.jetbrains-mono
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };

      # Dizüstünün LCD paneline uygun alt piksel işleme.
      subpixel.rgba = "rgb";
      hinting.style = "slight";
    };
  };
}
