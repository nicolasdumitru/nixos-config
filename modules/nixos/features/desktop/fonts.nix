{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.fonts;
in
{
  options.modules.desktop.fonts.enable = lib.mkEnableOption "the font collection";

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      jetbrains-mono
      corefonts
      vista-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
    ];
  };
}
