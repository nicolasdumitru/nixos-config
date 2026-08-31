{ pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  environment.systemPackages = with pkgs; [
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
  ];
}
