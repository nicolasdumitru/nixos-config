# modules/file-utils.nix
{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Compression
    gnutar
    gzip
    xz
    zip
    unzip

    # Synchronization
    rsync

    # Convenient file management
    lf # Terminal file manager
    fzf # Fuzzy finder
    rename # Bulk renamer
  ];
}
