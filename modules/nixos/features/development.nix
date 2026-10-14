{ pkgs, ... }:

{
  systemd.coredump.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.nix-ld.enable = true;
  # Required by the .NET SQL Tools Service downloaded by VS Code's MSSQL extension.
  programs.nix-ld.libraries = [ pkgs.icu ];
}
