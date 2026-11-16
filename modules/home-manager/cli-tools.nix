{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.cli-tools;
in
{
  options.modules.cli-tools.enable = lib.mkEnableOption "command-line tools and the GnuPG agent";

  config = lib.mkIf cfg.enable {
    services.gpg-agent = {
      enable = true;
      pinentry.package =
        if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gnome3;
    };

    home.packages = with pkgs; [
      diffutils
      findutils
      gnugrep
      gnused
      gawk
      ripgrep
      ripgrep-all
      fd
      eza
      bat
      gnupg
      gnutar
      gzip
      xz
      zip
      unzip
      p7zip
      rsync
      lf
      fzf
      rename
      dos2unix
      psmisc # for `fuser` and `pstree`, among others
    ];
  };
}
