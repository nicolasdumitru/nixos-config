{
  pkgs,
  ...
}:

{
  # GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  environment.systemPackages = with pkgs; [
    # Core Unix utilities
    coreutils
    diffutils
    findutils
    gnugrep
    gnused
    gawk

    # Enhanced Unix utilities
    ripgrep # Fast & recursive grep
    ripgrep-all # ripgrep for non-plain-text files
    fd # Fast find alternative
    eza # Modern ls replacement
    bat # Cat clone with syntax highlighting

    # Encryption & signing
    gnupg
  ];
}
