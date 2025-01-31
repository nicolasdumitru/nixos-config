{
  pkgs,
  ...
}:

{

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
  ];
}
