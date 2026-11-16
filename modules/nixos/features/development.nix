{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.development;
in
{
  options.modules.development.enable = lib.mkEnableOption "system support for development tools";

  config = lib.mkIf cfg.enable {
    systemd.coredump.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # The dotfiles hook direnv into the shells themselves.
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
    programs.nix-ld.enable = true;
    # Required by the .NET SQL Tools Service downloaded by VS Code's MSSQL extension.
    programs.nix-ld.libraries = [ pkgs.icu ];
  };
}
